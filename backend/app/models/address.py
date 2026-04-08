from typing import Annotated
from sqlmodel import SQLModel, Field


class Address(SQLModel, table=True):
    __tablename__ = "addresses"

    id: Annotated[int, Field(primary_key=True)] = None
    full_address: str
    county: str | None = None