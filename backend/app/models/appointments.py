from datetime import date
from sqlmodel import SQLModel, Field


class AppointmentBase(SQLModel):
    client_name: str | None = None
    address: str
    appointment_date: date
    roundtrip_distance: float


class Appointment(AppointmentBase, table= True):
    __tablename__ = 'appointments'

    id: int | None = Field(default=None, primary_key=True)
    user_id: int | None = Field(foreign_key='users.id')


class AppontmentCreate(AppointmentBase):
    user_id: int


class AppointmentUpdate(AppointmentBase):
    client_name: str | None = None
    address: str | None = None
    appointment_date: date | None = None
    roundtrip_distance: float | None = None


class AppointmentPublic(AppointmentBase):
    id: int
    user_id: int