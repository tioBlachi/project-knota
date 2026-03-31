from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlmodel import Session, select

from app.core.security import create_access_token, verify_password
from app.db import get_session
from app.models.user import User
from app.services.login_rate_limiter import login_limiter


auth_router = APIRouter(prefix="/auth", tags=["auth"])


@auth_router.post("/login")
def login_user(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    session: Session = Depends(get_session),
):
    identifier = form_data.username.strip().lower()
    login_limiter.raise_if_blocked(identifier)

    user = session.exec(select(User).where(User.email == identifier)).first()

    if not user or not verify_password(form_data.password, user.hashed_password):
        login_limiter.record_failure(identifier)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    login_limiter.clear(identifier)
    access_token = create_access_token(data={"sub": str(user.id)})

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }
