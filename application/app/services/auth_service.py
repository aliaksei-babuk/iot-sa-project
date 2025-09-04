"""Authentication and authorization service."""
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import jwt
import hashlib
import secrets
import logging
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.config import settings
from app.models.database import User, APIKey
from app.schemas.auth import UserCreate, UserResponse, LoginRequest, TokenResponse, APIKeyCreate, APIKeyResponse
from app.schemas.auth import UserRole

logger = logging.getLogger(__name__)

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    """Service for authentication and authorization."""
    
    def __init__(self, db_session: Session):
        self.db = db_session
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash."""
        return pwd_context.verify(plain_password, hashed_password)
    
    def get_password_hash(self, password: str) -> str:
        """Hash a password."""
        return pwd_context.hash(password)
    
    def create_user(self, user_data: UserCreate) -> UserResponse:
        """Create a new user."""
        try:
            # Check if user already exists
            existing_user = self.db.query(User).filter(
                (User.username == user_data.username) | (User.email == user_data.email)
            ).first()
            
            if existing_user:
                raise ValueError("User with this username or email already exists")
            
            # Create new user
            user = User(
                username=user_data.username,
                email=user_data.email,
                hashed_password=self.get_password_hash(user_data.password),
                role=user_data.role.value
            )
            
            self.db.add(user)
            self.db.commit()
            self.db.refresh(user)
            
            logger.info(f"User {user_data.username} created successfully")
            return UserResponse.from_orm(user)
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to create user: {e}")
            raise
    
    def authenticate_user(self, username: str, password: str) -> Optional[UserResponse]:
        """Authenticate a user with username and password."""
        try:
            user = self.db.query(User).filter(
                (User.username == username) | (User.email == username)
            ).first()
            
            if not user or not self.verify_password(password, user.hashed_password):
                return None
            
            # Update last login
            user.last_login = datetime.utcnow()
            self.db.commit()
            
            return UserResponse.from_orm(user)
            
        except Exception as e:
            logger.error(f"Failed to authenticate user: {e}")
            raise
    
    def create_access_token(self, user: UserResponse) -> TokenResponse:
        """Create access token for user."""
        try:
            expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
            
            to_encode = {
                "sub": user.id,
                "username": user.username,
                "role": user.role,
                "exp": expire
            }
            
            encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
            
            return TokenResponse(
                access_token=encoded_jwt,
                token_type="bearer",
                expires_in=settings.access_token_expire_minutes * 60
            )
            
        except Exception as e:
            logger.error(f"Failed to create access token: {e}")
            raise
    
    def verify_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Verify and decode JWT token."""
        try:
            payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
            return payload
        except jwt.ExpiredSignatureError:
            logger.warning("Token has expired")
            return None
        except jwt.JWTError as e:
            logger.warning(f"Invalid token: {e}")
            return None
    
    def get_user_by_id(self, user_id: str) -> Optional[UserResponse]:
        """Get user by ID."""
        try:
            user = self.db.query(User).filter(User.id == user_id).first()
            if user:
                return UserResponse.from_orm(user)
            return None
        except Exception as e:
            logger.error(f"Failed to get user by ID: {e}")
            raise
    
    def create_api_key(self, user_id: str, api_key_data: APIKeyCreate) -> APIKeyResponse:
        """Create API key for user."""
        try:
            # Generate API key
            key_value = secrets.token_urlsafe(32)
            key_hash = hashlib.sha256(key_value.encode()).hexdigest()
            
            # Create API key record
            api_key = APIKey(
                user_id=user_id,
                key_name=api_key_data.key_name,
                key_hash=key_hash,
                permissions=api_key_data.permissions,
                expires_at=api_key_data.expires_at
            )
            
            self.db.add(api_key)
            self.db.commit()
            self.db.refresh(api_key)
            
            logger.info(f"API key {api_key_data.key_name} created for user {user_id}")
            
            return APIKeyResponse(
                id=api_key.id,
                key_name=api_key.key_name,
                key_value=key_value,  # Only returned on creation
                permissions=api_key.permissions,
                expires_at=api_key.expires_at,
                is_active=api_key.is_active,
                created_at=api_key.created_at
            )
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to create API key: {e}")
            raise
    
    def verify_api_key(self, api_key: str) -> Optional[UserResponse]:
        """Verify API key and return associated user."""
        try:
            key_hash = hashlib.sha256(api_key.encode()).hexdigest()
            
            api_key_record = self.db.query(APIKey).filter(
                APIKey.key_hash == key_hash,
                APIKey.is_active == True
            ).first()
            
            if not api_key_record:
                return None
            
            # Check expiration
            if api_key_record.expires_at and api_key_record.expires_at < datetime.utcnow():
                return None
            
            # Update last used
            api_key_record.last_used = datetime.utcnow()
            self.db.commit()
            
            # Get user
            user = self.db.query(User).filter(User.id == api_key_record.user_id).first()
            if user and user.is_active:
                return UserResponse.from_orm(user)
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to verify API key: {e}")
            raise
    
    def revoke_api_key(self, api_key_id: str, user_id: str) -> bool:
        """Revoke an API key."""
        try:
            api_key = self.db.query(APIKey).filter(
                APIKey.id == api_key_id,
                APIKey.user_id == user_id
            ).first()
            
            if not api_key:
                return False
            
            api_key.is_active = False
            self.db.commit()
            
            logger.info(f"API key {api_key_id} revoked for user {user_id}")
            return True
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to revoke API key: {e}")
            raise
    
    def list_user_api_keys(self, user_id: str) -> list[APIKeyResponse]:
        """List API keys for a user."""
        try:
            api_keys = self.db.query(APIKey).filter(APIKey.user_id == user_id).all()
            
            return [
                APIKeyResponse(
                    id=key.id,
                    key_name=key.key_name,
                    key_value="***",  # Never return actual key value
                    permissions=key.permissions,
                    expires_at=key.expires_at,
                    is_active=key.is_active,
                    created_at=key.created_at
                )
                for key in api_keys
            ]
            
        except Exception as e:
            logger.error(f"Failed to list API keys: {e}")
            raise
    
    def check_permission(self, user: UserResponse, required_role: UserRole) -> bool:
        """Check if user has required role."""
        role_hierarchy = {
            UserRole.RESEARCHER: 1,
            UserRole.OPERATOR: 2,
            UserRole.ADMIN: 3
        }
        
        user_level = role_hierarchy.get(UserRole(user.role), 0)
        required_level = role_hierarchy.get(required_role, 0)
        
        return user_level >= required_level
