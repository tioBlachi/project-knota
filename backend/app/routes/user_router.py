from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.db import get_session
from app.models.user import User, UserCreate, UserPublic
from app.core.security import hash_password

user_router = APIRouter(prefix="/users", tags=["users"])


@user_router.post("/", response_model=UserPublic, status_code=status.HTTP_201_CREATED)
def create_user(user_data: UserCreate, session: Session = Depends(get_session)):
    existing_user = session.exec(
        select(User).where(User.email == user_data.email)
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with that email already exists",
        )

    hashed_pw = hash_password(user_data.password)

    new_user = User(
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        company_name=user_data.company_name,
        address=user_data.address,
        email=user_data.email,
        hashed_password=hashed_pw,
        join_date=date.today(),
    )

    session.add(new_user)
    session.commit()
    session.refresh(new_user)

    return new_user