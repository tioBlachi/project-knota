from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.db import get_session
from app.models.user import User, UserCreate, UserPublic, UserUpdate
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

@user_router.patch('/{user_id}', response_model=UserPublic)
def update_user(
    user_id: int,
    user_data: UserUpdate,
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(status_code=404, detail='User not found')
    
    user_data_dump = user_data.model_dump(exclude_unset=True)

    if 'password' in user_data_dump:
        user.hashed_password = hash(user_data_dump.pop('password'))

    for key, value in user_data_dump.items():
        setattr(user, key, value)

    session.add(user)
    session.commit()
    session.refresh(user)

    return user