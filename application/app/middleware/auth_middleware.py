"""Authentication middleware."""
from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
import logging
from datetime import datetime

from app.services.auth_service import AuthService
from app.services.database import db_service

logger = logging.getLogger(__name__)

security = HTTPBearer(auto_error=False)


class AuthMiddleware:
    """Authentication middleware for protecting routes."""
    
    def __init__(self):
        self.auth_service = None
    
    def get_auth_service(self) -> AuthService:
        """Get auth service instance."""
        if not self.auth_service:
            session = db_service.get_session()
            self.auth_service = AuthService(session)
        return self.auth_service
    
    async def __call__(self, request: Request, call_next):
        """Process request through authentication middleware."""
        # Skip auth for certain paths
        if request.url.path in ["/", "/health", "/docs", "/openapi.json", "/metrics"]:
            response = await call_next(request)
            return response
        
        # Check for API key in headers
        api_key = request.headers.get("X-API-Key")
        if api_key:
            try:
                auth_service = self.get_auth_service()
                user = auth_service.verify_api_key(api_key)
                if user:
                    request.state.user = user
                    response = await call_next(request)
                    return response
            except Exception as e:
                logger.error(f"API key verification failed: {e}")
        
        # Check for Bearer token
        authorization = request.headers.get("Authorization")
        if authorization and authorization.startswith("Bearer "):
            try:
                token = authorization.split(" ")[1]
                auth_service = self.get_auth_service()
                payload = auth_service.verify_token(token)
                
                if payload:
                    user = auth_service.get_user_by_id(payload["sub"])
                    if user:
                        request.state.user = user
                        response = await call_next(request)
                        return response
            except Exception as e:
                logger.error(f"Token verification failed: {e}")
        
        # For POC, allow unauthenticated access with a default user
        # In production, this should be removed
        from app.schemas.auth import UserResponse, UserRole
        request.state.user = UserResponse(
            id="poc-user",
            username="poc",
            email="poc@example.com",
            role=UserRole.ADMIN,
            is_active=True,
            created_at=datetime.utcnow(),
            last_login=None
        )
        
        response = await call_next(request)
        return response


# Global auth middleware instance
auth_middleware = AuthMiddleware()
