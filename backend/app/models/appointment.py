import uuid as uuid_pkg
from uuid import UUID
from datetime import datetime
from typing import TYPE_CHECKING, Annotated

from sqlmodel import SQLModel, Field, Relationship, Column, DateTime
from pydantic import StringConstraints

if TYPE_CHECKING:
    from .user import User
    from .distance import Distance


class AppointmentBase(SQLModel):
    client_name: Annotated[str | None, StringConstraints(strip_whitespace=True, max_length=100)] = None
    destination_address: Annotated[str, StringConstraints(to_lower=True, strip_whitespace=True, max_length=100)]
    appointment_date: Annotated[datetime, Field(
        sa_column=Column(
            DateTime(timezone=True),
            nullable=False),
    )]


class Appointment(AppointmentBase, table= True):
    """
    Database table for appointments.
    Each appointment belongs to one user and can optionally reference
    a cached distance record to lower the amount of Google Routes API
    calls.
    """
    __tablename__ = 'appointments'

    id: Annotated[UUID, Field(default_factory=uuid_pkg.uuid4, primary_key=True, index=True)]
    roundtrip_distance: float | None = None
    user_id: Annotated[UUID, Field(foreign_key='users.id', ondelete='CASCADE')]
    distance_id: Annotated[int | None, Field(default=None, foreign_key='distances.id')]
    user: 'User' = Relationship(back_populates='appointments')
    distance: 'Distance' = Relationship(back_populates='appointments')


class AppointmentCreate(AppointmentBase):
    """
    Request model used when creating a new appoinment.
    """
    pass


class AppointmentUpdate(SQLModel):
    """
    Request model used when partially updating an appointment.
    All fields are optional
    """
    client_name: Annotated[str | None, StringConstraints(strip_whitespace=True, max_length=100)] = None
    destination_address: Annotated[str | None, StringConstraints(to_lower=True, strip_whitespace=True)] = None
    appointment_date: datetime | None = None


class AppointmentPublic(AppointmentBase):
    """
    Response model returned to the frontend
    """
    id: UUID
    user_id: UUID
    roundtrip_distance: float | None = None
    distance_id: int | None = None
