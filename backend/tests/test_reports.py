from datetime import datetime, timezone

import pytest
from fastapi import HTTPException, Response

from app.routes.report_router import get_mileage_report


def test_mileage_report_returns_pdf_response(
    session, user_factory, appointment_factory, monkeypatch
):
    user = user_factory()
    called = {}
    appointment_factory(
        user_id=user.id,
        appointment_date=datetime(2026, 2, 10, 9, 0, tzinfo=timezone.utc),
    )

    def fake_generate_pdf_report(appointments, current_user, year):
        called["appointment_count"] = len(appointments)
        called["user_id"] = current_user.id
        called["year"] = year
        return Response(content=b"pdf-bytes", media_type="application/pdf")

    monkeypatch.setattr(
        "app.routes.report_router.generate_pdf_report",
        fake_generate_pdf_report,
    )

    response = get_mileage_report(
        current_user=user,
        year=2026,
        session=session,
    )

    assert called["appointment_count"] == 1
    assert called["user_id"] == user.id
    assert called["year"] == 2026
    assert response.headers["content-type"] == "application/pdf"
    assert response.body == b"pdf-bytes"


def test_mileage_report_returns_404_when_no_appointments(session, user_factory):
    user = user_factory()

    with pytest.raises(HTTPException) as exc_info:
        get_mileage_report(current_user=user, year=2026, session=session)

    assert exc_info.value.status_code == 404
    assert exc_info.value.detail == "No appointments found for 2026"
