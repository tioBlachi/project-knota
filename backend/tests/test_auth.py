from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.routes.auth_router import login_user


def test_login_returns_access_token(session, user_factory):
    user_factory(email="person@example.com", password="Password1!")
    form_data = SimpleNamespace(
        username="PERSON@example.com",
        password="Password1!",
    )

    response = login_user(form_data=form_data, session=session)

    assert response["token_type"] == "bearer"
    assert response["access_token"]


def test_login_with_invalid_password_returns_401(session, user_factory):
    user_factory(email="person@example.com", password="Password1!")
    form_data = SimpleNamespace(
        username="person@example.com",
        password="WrongPassword1!",
    )

    with pytest.raises(HTTPException) as exc_info:
        login_user(form_data=form_data, session=session)

    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Invalid credentials"
