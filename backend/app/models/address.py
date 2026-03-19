from typing import Optional
from sqlmodel import SQLModel, Field


class Address(SQLModel, table=True):
    __tablename__ = "addresses"

    id: Optional[int] = Field(default=None, primary_key=True)
    full_address: str
    county: Optional[str] = None