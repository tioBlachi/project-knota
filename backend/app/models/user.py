"""File containing data and table models related to User
"""
import uuid as uuid_pkg
from datetime import datetime
from typing import TYPE_CHECKING, Annotated
from uuid import UUID

from sqlmodel import SQLModel, Field, Relationship
from pydantic import EmailStr, StringConstraints

if TYPE_CHECKING:
    from .appointment import Appointment

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
    join_date: Annotated[datetime, Field(default=datetime.now())]
    appointments: list['Appointment'] = Relationship(back_populates='user', cascade_delete=True)


class UserCreate(UserBase):
    password: str


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
