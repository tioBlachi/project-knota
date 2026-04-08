"""File containing data and table models related to User
"""
import re
import uuid as uuid_pkg
from datetime import datetime
from typing import TYPE_CHECKING, Annotated
from uuid import UUID

from sqlmodel import SQLModel, Field, Relationship
from pydantic import EmailStr, StringConstraints, field_validator

if TYPE_CHECKING:
    from .appointment import Appointment


def _validate_password_strength(password: str) -> str:
    if len(password) < 8:
        raise ValueError('Password must be at least 8 characters long')
    if not re.search(r'[A-Z]', password):
        raise ValueError('Password must contain an uppercase letter')
    if not re.search(r'[a-z]', password):
        raise ValueError('Password must contain a lowercase letter')
    if not re.search(r'[0-9]', password):
        raise ValueError('Password must contain a number')
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        raise ValueError('Password must contain a special character')
    return password

class UserBase(SQLModel):
    """
    Base class for the User. Will be inherited from to set up the proper
    Request and Response models
    """
    first_name: str
    last_name: str
    company_name: str | None = None
    address: Annotated[str, StringConstraints(to_lower=True, strip_whitespace=True)]
    email: Annotated[EmailStr, Field(index=True, unique=True), StringConstraints(to_lower=True, strip_whitespace=True)]


class User(UserBase, table=True):
    __tablename__ = 'users'

    id: Annotated[UUID, Field(default_factory=uuid_pkg.uuid4, primary_key=True, index=True, nullable=False)]
    hashed_password: str
    join_date: Annotated[datetime, Field(default_factory=datetime.now)]
    appointments: list['Appointment'] = Relationship(back_populates='user', cascade_delete=True)


class UserCreate(UserBase):
    password: str

    @field_validator('password')
    @classmethod
    def validate_password(cls, value: str) -> str:
        return _validate_password_strength(value)


class UserPublic(UserBase):
    """
    The publicly returned response model. Will not return passwords from the backend
    """
    id: UUID
    join_date: datetime


class UserLogin(SQLModel):
    email: Annotated[EmailStr, StringConstraints(to_lower=True, strip_whitespace=True)]
    password: str


class UserUpdate(SQLModel):
    first_name: str | None = None
    last_name: str | None = None
    company_name: str | None = None
    address: Annotated[str | None, StringConstraints(to_lower=True, strip_whitespace=True)] = None
    email: Annotated[EmailStr | None, StringConstraints(to_lower=True, strip_whitespace=True)] = None
    password: str | None = None

    @field_validator('password')
    @classmethod
    def validate_password(cls, value: str | None) -> str | None:
        if value is None:
            return value
        return _validate_password_strength(value)
