import uuid as uuid_pkg
from uuid import UUID
from datetime import date, time
from typing import TYPE_CHECKING, Annotated

from sqlmodel import SQLModel, Field, Relationship
from pydantic import StringConstraints

if TYPE_CHECKING:
    from .user import User
    from .distance import Distance


class AppointmentBase(SQLModel):
    client_name: str | None = None
    destination_address: Annotated[str, StringConstraints(to_lower=True, strip_whitespace=True)]
    appointment_date: date
    appointment_time: time


class Appointment(AppointmentBase, table= True):
    """
    Database table for appointments.
    Each appointment belongs to one user and can optionally reference
    a cached distance record to lower the amount of Google Routes API
    calls.
    """
    __tablename__ = 'appointments'

    id: UUID = Field(default_factory=uuid_pkg.uuid4, primary_key=True, index=True)
    roundtrip_distance: float | None = None
    user_id: UUID = Field(foreign_key='users.id', ondelete='CASCADE')
    distance_id: int | None = Field(default=None, foreign_key='distances.id')
    user: 'User' = Relationship(back_populates='appointments')
    distance: 'Distance' = Relationship(back_populates='appointments')


class AppointmentCreate(AppointmentBase):
    """
    Request model used when creating a new appoinment.
    """
    client_name: str | None
    destination_address: Annotated[str, StringConstraints(to_lower=True, strip_whitespace=True)]
    appointment_date: date


class AppointmentUpdate(SQLModel):
    """
    Request model used when partially updating an appointment.
    All fields are optional
    """
    client_name: str | None = None
    destination_address: Annotated[str | None, StringConstraints(to_lower=True, strip_whitespace=True)] = None
    appointment_date: date | None = None


class AppointmentPublic(AppointmentBase):
    """
    Response model returned to the frontend
    """
    id: UUID
    user_id: UUID
    roundtrip_distance: float | None = None
    distance_id: int | None = None