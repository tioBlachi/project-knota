"""
Router for HTTP requests related to appointment CRUD operations.
"""
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status, Response
from sqlmodel import Session, select, extract

from app.db import get_session
from app.models.user import User
from app.models.appointment import (
    Appointment,
    AppointmentCreate,
    AppointmentPublic,
    AppointmentUpdate,
)
from app.services.distance_service import get_or_create_distance
from app.core.security import get_current_user


appointment_router = APIRouter(prefix='/appointments', tags=["appointments"], )


@appointment_router.post("", response_model=AppointmentPublic, status_code=status.HTTP_201_CREATED)
def create_appointment(
    appointment_data: AppointmentCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    Creates an appointment by taking in an AppointmentCreate object 
    """
    distance = get_or_create_distance(
        session=session,
        origin_address=current_user.address,
        destination_address=appointment_data.destination_address,
    )

    extra_data = {
        'user_id': current_user.id,
        'distance_id': distance.id,
        'roundtrip_distance': distance.roundtrip_distance
    }

    new_appointment = Appointment.model_validate(appointment_data, update=extra_data)
    
    session.add(new_appointment)
    session.commit()
    session.refresh(new_appointment)

    return new_appointment


@appointment_router.get("", response_model=list[AppointmentPublic])
def get_appointment_list(
    current_user: Annotated[User, Depends(get_current_user)],
    year: int | None = None,
    session: Session = Depends(get_session),
):
    statement = (
        select(Appointment)
        .where(Appointment.user_id == current_user.id)
        .order_by(Appointment.appointment_date)
    )

    if year is not None:
        statement = statement.where(
            extract('year', Appointment.appointment_date) == year
        )

    appointments = session.exec(statement).all()

    return appointments

@appointment_router.get("/{appointment_id}", response_model=AppointmentPublic)
def get_appointment(
    appointment_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Session = Depends(get_session),
):    
    appointment = session.get(Appointment, appointment_id)

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )
    
    if appointment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Unauthorized access'
            )

    return appointment



@appointment_router.patch("/{appointment_id}", response_model=AppointmentPublic)
def update_appointment(
    appointment_id: UUID,
    appointment_data: AppointmentUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):   
    appointment = session.get(Appointment, appointment_id)

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )
    
    if appointment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Unauthorized access'
            )

    appointment_data_dump = appointment_data.model_dump(exclude_unset=True)

    if 'destination_address' in appointment_data_dump:
        distance = get_or_create_distance(
            session=session,
            origin_address=current_user.address,
            destination_address=appointment_data_dump["destination_address"],
        )

        appointment.distance_id = distance.id
        appointment.roundtrip_distance = distance.roundtrip_distance

    appointment.sqlmodel_update(appointment_data_dump)

    session.add(appointment)
    session.commit()
    session.refresh(appointment)

    return appointment


@appointment_router.delete("/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_appointment(
    appointment_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Session = Depends(get_session),
) -> Response:
    appointment = session.get(Appointment, appointment_id)

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    if appointment.user_id != current_user.id:
        raise HTTPException(status_code=403, detail='Access forbidden')

    session.delete(appointment)
    session.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)
