from datetime import datetime, timezone
from types import SimpleNamespace

from app.models.appointment import AppointmentCreate, AppointmentUpdate
from app.routes.appointment_router import (
    create_appointment,
    delete_appointment,
    get_appointment_list,
    update_appointment,
)


def test_create_appointment_uses_distance_service(
    session, user_factory, monkeypatch
):
    user = user_factory(address="123 main st")
    called = {}

    def fake_distance(**kwargs):
        called["origin_address"] = kwargs["origin_address"]
        called["destination_address"] = kwargs["destination_address"]
        return SimpleNamespace(id=7, roundtrip_distance=18.25)

    monkeypatch.setattr(
        "app.routes.appointment_router.get_or_create_distance",
        fake_distance,
    )

    response = create_appointment(
        appointment_data=AppointmentCreate(
            client_name="Client A",
            destination_address="456 elm st",
            appointment_date=datetime(2026, 4, 2, 14, 30, tzinfo=timezone.utc),
        ),
        current_user=user,
        session=session,
    )

    assert called["origin_address"] == "123 main st"
    assert called["destination_address"] == "456 elm st"
    assert response.user_id == user.id
    assert response.distance_id == 7
    assert response.roundtrip_distance == 18.25


def test_get_appointment_list_is_sorted_by_time(
    session, user_factory, appointment_factory
):
    user = user_factory()
    appointment_factory(
        user_id=user.id,
        client_name="Late",
        appointment_date=datetime(2026, 4, 2, 17, 0, tzinfo=timezone.utc),
    )
    appointment_factory(
        user_id=user.id,
        client_name="Early",
        appointment_date=datetime(2026, 4, 2, 9, 0, tzinfo=timezone.utc),
    )

    response = get_appointment_list(current_user=user, year=2026, session=session)

    assert [item.client_name for item in response] == ["Early", "Late"]


def test_update_appointment_recomputes_distance_when_address_changes(
    session, user_factory, appointment_factory, monkeypatch
):
    user = user_factory(address="123 main st")
    called = {}
    appointment = appointment_factory(
        user_id=user.id,
        client_name="Client A",
        destination_address="456 elm st",
        appointment_date=datetime(2026, 4, 2, 14, 30, tzinfo=timezone.utc),
        roundtrip_distance=10.0,
        distance_id=1,
    )

    def fake_distance(**kwargs):
        called["origin_address"] = kwargs["origin_address"]
        called["destination_address"] = kwargs["destination_address"]
        return SimpleNamespace(id=9, roundtrip_distance=22.75)

    monkeypatch.setattr(
        "app.routes.appointment_router.get_or_create_distance",
        fake_distance,
    )

    response = update_appointment(
        appointment_id=appointment.id,
        appointment_data=AppointmentUpdate(destination_address="789 pine st"),
        current_user=user,
        session=session,
    )

    assert called["origin_address"] == "123 main st"
    assert called["destination_address"] == "789 pine st"
    assert response.distance_id == 9
    assert response.roundtrip_distance == 22.75
    assert response.destination_address == "789 pine st"


def test_delete_appointment_removes_record(
    session, user_factory, appointment_factory
):
    user = user_factory()
    appointment = appointment_factory(
        user_id=user.id,
        appointment_date=datetime(2026, 4, 2, 14, 30, tzinfo=timezone.utc),
    )

    response = delete_appointment(
        appointment_id=appointment.id,
        current_user=user,
        session=session,
    )

    assert response.status_code == 204
    assert session.get(type(appointment), appointment.id) is None
