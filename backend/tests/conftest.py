import os

import pytest
from fastapi.testclient import TestClient
from sqlmodel import SQLModel, Session, create_engine

os.environ.setdefault("DATABASE_URL", "sqlite://")
os.environ.setdefault("GOOGLE_API_KEY", "test-google-api-key")
os.environ.setdefault("SECRET_KEY", "test-secret-key")

from app.core.security import create_access_token, hash_password
from app.db import get_session
from app.main import app
from app.models.appointment import Appointment
from app.models.distance import Distance
from app.models.user import User
from app.services.login_rate_limiter import login_limiter


@pytest.fixture
def engine(tmp_path):
    db_file = tmp_path / "test.db"
    engine = create_engine(
        f"sqlite:///{db_file}",
        connect_args={"check_same_thread": False},
    )
    SQLModel.metadata.create_all(engine)
    yield engine
    SQLModel.metadata.drop_all(engine)


@pytest.fixture(autouse=True)
def setup_test_database(engine):
    def override_get_session():
        with Session(engine) as session:
            yield session

    app.dependency_overrides[get_session] = override_get_session
    login_limiter._attempts.clear()
    yield
    app.dependency_overrides.clear()
    login_limiter._attempts.clear()


@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client


@pytest.fixture
def session(engine):
    with Session(engine) as session:
        yield session


@pytest.fixture
def user_factory(session):
    def make_user(**overrides):
        number = overrides.pop("index", 1)
        password = overrides.pop("password", "StrongPass1!")
        user = User(
            first_name=overrides.pop("first_name", f"Test{number}"),
            last_name=overrides.pop("last_name", "User"),
            company_name=overrides.pop("company_name", None),
            address=overrides.pop("address", "123 main st"),
            email=overrides.pop("email", f"user{number}@example.com"),
            hashed_password=hash_password(password),
            **overrides,
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        return user

    return make_user


@pytest.fixture
def auth_headers():
    def make_headers(user):
        token = create_access_token(data={"sub": str(user.id)})
        return {"Authorization": f"Bearer {token}"}

    return make_headers


@pytest.fixture
def appointment_factory(session):
    def make_appointment(**overrides):
        appointment = Appointment(
            client_name=overrides.pop("client_name", "Client"),
            destination_address=overrides.pop("destination_address", "456 elm st"),
            appointment_date=overrides.pop("appointment_date"),
            roundtrip_distance=overrides.pop("roundtrip_distance", 12.5),
            user_id=overrides.pop("user_id"),
            distance_id=overrides.pop("distance_id", None),
            **overrides,
        )
        session.add(appointment)
        session.commit()
        session.refresh(appointment)
        return appointment

    return make_appointment


@pytest.fixture
def distance_factory(session):
    def make_distance(**overrides):
        distance = Distance(
            origin_address=overrides.pop("origin_address", "123 main st"),
            destination_address=overrides.pop("destination_address", "456 elm st"),
            roundtrip_distance=overrides.pop("roundtrip_distance", 12.5),
            **overrides,
        )
        session.add(distance)
        session.commit()
        session.refresh(distance)
        return distance

    return make_distance
