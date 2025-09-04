"""Authentication-related Pydantic schemas."""
from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    """User role enumeration."""
    ADMIN = "admin"
    OPERATOR = "operator"
    RESEARCHER = "researcher"


class UserCreate(BaseModel):
    """Schema for creating a new user."""
    username: str = Field(..., min_length=3, max_length=50, description="Username")
    email: EmailStr = Field(..., description="User email")
    password: str = Field(..., min_length=8, description="User password")
    role: UserRole = Field(UserRole.OPERATOR, description="User role")


class UserUpdate(BaseModel):
    """Schema for updating user information."""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None


class UserResponse(BaseModel):
    """Schema for user response."""
    id: str
    username: str
    email: str
    role: UserRole
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime]

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    """Schema for login request."""
    username: str = Field(..., description="Username or email")
    password: str = Field(..., description="Password")


class TokenResponse(BaseModel):
    """Schema for token response."""
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class APIKeyCreate(BaseModel):
    """Schema for creating API key."""
    key_name: str = Field(..., description="API key name")
    permissions: Optional[list[str]] = Field(None, description="API key permissions")
    expires_at: Optional[datetime] = Field(None, description="API key expiration")


class APIKeyResponse(BaseModel):
    """Schema for API key response."""
    id: str
    key_name: str
    key_value: str  # Only returned on creation
    permissions: Optional[list[str]]
    expires_at: Optional[datetime]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
