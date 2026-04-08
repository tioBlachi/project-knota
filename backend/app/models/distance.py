from typing import TYPE_CHECKING, Annotated

from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import UniqueConstraint, CheckConstraint

from pydantic import StringConstraints

if TYPE_CHECKING:
    from .appointment import Appointment


class DistanceBase(SQLModel):
    origin_address: Annotated[str, StringConstraints(to_lower=True, strip_whitespace=True, max_length=100)]
    destination_address: Annotated[str, StringConstraints(to_lower=True, strip_whitespace=True, max_length=100)]
    roundtrip_distance: float


class Distance(DistanceBase, table=True):
    __tablename__ = 'distances'
    __table_args__ = (
        UniqueConstraint(
            'origin_address',
            'destination_address',
            name='uq_distance_route',
        ),
        CheckConstraint(
            'origin_address < destination_address',
            name='check_address_order'),
    )

    id: int | None = Field(default=None, primary_key=True)
    appointments: list['Appointment'] = Relationship(back_populates='distance')


class DistanceCreate(DistanceBase):
    pass


class DistancePublic(DistanceBase):
    id: int