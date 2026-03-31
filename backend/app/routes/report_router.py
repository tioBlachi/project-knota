from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlmodel import Session, extract, select

from app.core.security import get_current_user
from app.db import get_session
from app.models.appointment import Appointment
from app.models.user import User
from app.services.pdf_service import generate_pdf_report


report_router = APIRouter(prefix="/reports", tags=["reports"])


@report_router.get("/mileage")
def get_mileage_report(
    current_user: Annotated[User, Depends(get_current_user)],
    year: int | None = None,
    session: Session = Depends(get_session),
) -> Response:
    report_year = year or datetime.now().year

    appointments = session.exec(
        select(Appointment)
        .where(Appointment.user_id == current_user.id)
        .where(extract("year", Appointment.appointment_date) == report_year)
        .order_by(Appointment.appointment_date, Appointment.id)
    ).all()

    if not appointments:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No appointments found for {report_year}",
        )

    return generate_pdf_report(appointments, current_user, report_year)
