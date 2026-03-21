from typing import TYPE_CHECKING

from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import UniqueConstraint

if TYPE_CHECKING:
    from .appointment import Appointment


class DistanceBase(SQLModel):
    origin_address: str
    destination_address: str
    roundtrip_distance: float


class Distance(DistanceBase, table=True):
    __tablename__ = 'distances'
    __table_args__ = (
        UniqueConstraint(
            'origin_address',
            'destination_address',
            name='uq_distance_route',
        ),
    )

    id: int | None = Field(default=None, primary_key=True)
    appointments: list['Appointment'] = Relationship(back_populates='distance')


class DistanceCreate(DistanceBase):
    pass


class DistancePublic(DistanceBase):
    id: int