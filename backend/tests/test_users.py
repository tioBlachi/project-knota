import pytest
from fastapi import HTTPException
from sqlmodel import select

from app.models.user import User, UserCreate, UserUpdate
from app.routes.user_router import create_user, delete_user, get_user, update_user


def test_create_user_hashes_password_and_returns_public_fields(session):
    response = create_user(
        UserCreate(
            first_name="Test",
            last_name="User",
            company_name="Knota LLC",
            address="123 Main St",
            email="test@example.com",
            password="Password1!",
        ),
        session=session,
    )

    assert response.email == "test@example.com"

    saved_user = session.exec(
        select(User).where(User.email == "test@example.com")
    ).one()
    assert saved_user.hashed_password != "Password1!"


def test_create_user_rejects_duplicate_email(session, user_factory):
    user_factory(email="test@example.com")

    with pytest.raises(HTTPException) as exc_info:
        create_user(
            UserCreate(
                first_name="Another",
                last_name="User",
                company_name=None,
                address="555 Oak St",
                email="test@example.com",
                password="Password1!",
            ),
            session=session,
        )

    assert exc_info.value.status_code == 400
    assert exc_info.value.detail == "A user with that email already exists"


def test_get_current_user_returns_profile(session, user_factory):
    user = user_factory(email="me@example.com", first_name="Jamie")

    response = get_user(current_user=user)

    assert response.id == user.id
    assert response.first_name == "Jamie"


def test_update_user_allows_owner_to_change_fields(session, user_factory):
    user = user_factory(email="me@example.com", first_name="Jamie")

    response = update_user(
        user_id=user.id,
        user_data=UserUpdate(first_name="Updated", company_name="New Name"),
        current_user=user,
        session=session,
    )

    assert response.first_name == "Updated"
    assert response.company_name == "New Name"


def test_delete_user_removes_account(session, user_factory):
    user = user_factory(email="delete@example.com")

    response = delete_user(
        user_id=user.id,
        current_user=user,
        session=session,
    )

    assert response.status_code == 204
    assert session.get(User, user.id) is None
