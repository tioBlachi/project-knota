from datetime import date
from sqlmodel import SQLModel, Field
from ..core.security import hash_password


class UserBase(SQLModel):
    first_name: str
    last_name: str
    company_name: str | None = None
    address: str
    email: str


class User(UserBase, table=True):
    __tablename__ = 'users'

    id: int | None = Field(default=None, primary_key=True)
    hashed_password: str
    join_date: date


class UserCreate(UserBase):
    password: str


class UserPublic(UserBase):
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

