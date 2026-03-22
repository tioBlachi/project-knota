"""
Router for HTTP requests related to appointment CRUD operations.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.db import get_session
from app.models.user import User
from app.models.appointment import (
    Appointment,
    AppointmentCreate,
    AppointmentPublic,
    AppointmentUpdate,
)
from app.services.distance_service import get_or_create_distance

appointment_router = APIRouter(tags=["appointments"])


@appointment_router.post(
    "/users/{user_id}/appointments",
    response_model=AppointmentPublic,
    status_code=status.HTTP_201_CREATED,
)
def create_appointment(
    user_id: int,
    appointment_data: AppointmentCreate,
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )


    distance = get_or_create_distance(
        session=session,
        origin_address=user.address,
        destination_address=appointment_data.destination_address,
    )

    extra_data = {
        'user_id': user.id,
        'distance_id': distance.id,
        'roundtrip_distance': distance.roundtrip_distance
    }

    new_appointment = Appointment.model_validate(appointment_data, update=extra_data)
    
    session.add(new_appointment)
    session.commit()
    session.refresh(new_appointment)

    return new_appointment


@appointment_router.get("/appointments/{appointment_id}", response_model=AppointmentPublic)
def get_appointment(
    appointment_id: int,
    session: Session = Depends(get_session),
):
    appointment = session.get(Appointment, appointment_id)

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )

    return appointment


@appointment_router.get("/users/{user_id}/appointments", response_model=list[AppointmentPublic])
def get_user_appointments(
    user_id: int,
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    appointments = session.exec(
        select(Appointment).where(Appointment.user_id == user_id)
    ).all()

    return appointments


@appointment_router.patch("/appointments/{appointment_id}", response_model=AppointmentPublic)
def update_appointment(
    appointment_id: int,
    appointment_data: AppointmentUpdate,
    session: Session = Depends(get_session),
):
    appointment = session.get(Appointment, appointment_id)

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )

    appointment_data_dump = appointment_data.model_dump(exclude_unset=True)

    if "destination_address" in appointment_data_dump:
        user = session.get(User, appointment.user_id)

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated user not found",
            )

        distance = get_or_create_distance(
            session=session,
            origin_address=user.address,
            destination_address=appointment_data_dump["destination_address"],
        )

        appointment.distance_id = distance.id
        appointment.roundtrip_distance = distance.roundtrip_distance

    appointment.sqlmodel_update(appointment_data_dump)

    session.add(appointment)
    session.commit()
    session.refresh(appointment)

    return appointment


@appointment_router.delete("/appointments/{appointment_id}")
def delete_appointment(
    appointment_id: int,
    session: Session = Depends(get_session),
):
    appointment = session.get(Appointment, appointment_id)

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )

    session.delete(appointment)
    session.commit()

    return {
        "message": "Appointment deleted",
        "appointment_id": appointment_id,
    }