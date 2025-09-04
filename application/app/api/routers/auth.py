"""Authentication API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Header
from typing import Optional
from datetime import datetime

from app.services.auth_service import AuthService
from app.schemas.auth import (
    UserCreate, UserResponse, LoginRequest, TokenResponse, 
    APIKeyCreate, APIKeyResponse, UserRole
)
from app.api.dependencies import get_db

router = APIRouter(prefix="/auth", tags=["authentication"])


def get_auth_service(db = Depends(get_db)) -> AuthService:
    """Get authentication service."""
    return AuthService(db)


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(
    user_data: UserCreate,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Register a new user."""
    try:
        user = auth_service.create_user(user_data)
        return user
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create user")


@router.post("/login", response_model=TokenResponse)
async def login(
    login_data: LoginRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Login user and get access token."""
    try:
        user = auth_service.authenticate_user(login_data.username, login_data.password)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password"
            )
        
        token = auth_service.create_access_token(user)
        return token
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to login")


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    authorization: Optional[str] = Header(None),
    auth_service: AuthService = Depends(get_auth_service)
):
    """Get current user information."""
    try:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid authorization header"
            )
        
        token = authorization.split(" ")[1]
        payload = auth_service.verify_token(token)
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token"
            )
        
        user = auth_service.get_user_by_id(payload["sub"])
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get user info")


@router.post("/api-keys", response_model=APIKeyResponse, status_code=status.HTTP_201_CREATED)
async def create_api_key(
    api_key_data: APIKeyCreate,
    authorization: Optional[str] = Header(None),
    auth_service: AuthService = Depends(get_auth_service)
):
    """Create API key for current user."""
    try:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid authorization header"
            )
        
        token = authorization.split(" ")[1]
        payload = auth_service.verify_token(token)
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token"
            )
        
        user_id = payload["sub"]
        api_key = auth_service.create_api_key(user_id, api_key_data)
        return api_key
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create API key")


@router.get("/api-keys", response_model=list[APIKeyResponse])
async def list_api_keys(
    authorization: Optional[str] = Header(None),
    auth_service: AuthService = Depends(get_auth_service)
):
    """List API keys for current user."""
    try:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid authorization header"
            )
        
        token = authorization.split(" ")[1]
        payload = auth_service.verify_token(token)
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token"
            )
        
        user_id = payload["sub"]
        api_keys = auth_service.list_user_api_keys(user_id)
        return api_keys
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to list API keys")


@router.delete("/api-keys/{api_key_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_api_key(
    api_key_id: str,
    authorization: Optional[str] = Header(None),
    auth_service: AuthService = Depends(get_auth_service)
):
    """Revoke an API key."""
    try:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid authorization header"
            )
        
        token = authorization.split(" ")[1]
        payload = auth_service.verify_token(token)
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token"
            )
        
        user_id = payload["sub"]
        success = auth_service.revoke_api_key(api_key_id, user_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="API key not found"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to revoke API key")


@router.post("/verify-api-key", response_model=UserResponse)
async def verify_api_key(
    api_key: str = Header(..., alias="X-API-Key"),
    auth_service: AuthService = Depends(get_auth_service)
):
    """Verify API key and get user information."""
    try:
        user = auth_service.verify_api_key(api_key)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired API key"
            )
        
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to verify API key")
