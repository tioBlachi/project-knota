"""File containing data and table models related to User
"""
from datetime import date
from typing import TYPE_CHECKING

from sqlmodel import SQLModel, Field, Relationship

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
    address: str
    email: str = Field(index=True, unique=True)


class User(UserBase, table=True):
    __tablename__ = 'users'

    id: int | None = Field(default=None, primary_key=True)
    hashed_password: str
    join_date: date
    appointments: list['Appointment'] = Relationship(back_populates='user', cascade_delete=True)


class UserCreate(UserBase):
    password: str


class UserPublic(UserBase):
    """
    The publicly returned response model. Will not return passwords from the backend
    """
    id: int
    join_date: date


class UserLogin(SQLModel):
    email: str
    password: str


class UserUpdate(SQLModel):
    first_name: str | None = None
    last_name: str | None = None
    company_name: str | None = None
    address: str | None = None
    email: str | None = None
    password: str | None = None
