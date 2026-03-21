"""
Router for HTTP requests that are relevant to user CRUD operations
"""
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.db import get_session
from app.models.user import User, UserCreate, UserPublic, UserUpdate, UserLogin
from app.core.security import hash_password, verify_password

user_router = APIRouter(prefix="/users", tags=["users"])


@user_router.get('/{user_id}', response_model=UserPublic)
def get_user(user_id: int, session: Session = Depends(get_session)):
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(status_code=404, detail='User not found')
    
    return user


@user_router.post("/", response_model=UserPublic, status_code=status.HTTP_201_CREATED)
def create_user(user_data: UserCreate, session: Session = Depends(get_session)):
    """
    Creates a user using the UserCreate class. Checks if email already exists in the database
    If so, raises an HTTPException. If the email is unique, the password is hashed before storage
    into the database. Returns the UserPublic that does not contain their password.
    """


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
        first_name=user_data.first_name.strip().title(),
        last_name=user_data.last_name.strip().title(),
        company_name=user_data.company_name.strip(),
        address=user_data.address.strip().lower(),
        email=user_data.email.strip().lower(),
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
    """Updates only the values given in the request body, if the user exists in the database. Otherwise, a 404 User 
    Not Found error is returned. Rehashes the new password (if given), checks if the email 
    already exists (to prevent multiple accounts patching the same email to an account after creation). User is then
    updated in the database
    """
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(status_code=404, detail='User not found')
    
    user_data_dump = user_data.model_dump(exclude_unset=True)

    if 'password' in user_data_dump:
        user.hashed_password = hash_password(user_data_dump.pop('password'))

    if 'email' in user_data_dump:
        existing_user = session.exec(
            select(User).where(User.email == user_data_dump['email'], User.id != user_id)
        ).first()

        if existing_user:
            raise HTTPException(status_code=400, detail='Email already in use')

    for key, value in user_data_dump.items():
        setattr(user, key, value)

    session.add(user)
    session.commit()
    session.refresh(user)

    return user


@user_router.post('/login')
def login_user(user_data: UserLogin, session: Session = Depends(get_session)):
    user = session.exec(
        select(User).where(User.email == user_data.email)
    ).first()

    if not user:
        raise HTTPException(status_code=401, detail='Invalid credentials')
    
    if not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail='Invalid credentials')
    
    return {'message': 'Login successful', 'user_id': user.id}


@user_router.delete('/{user_id}')
def delete_user(user_id: int, session: Session = Depends(get_session)):
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(status_code=404, detail='User does not exist')

    session.delete(user)
    session.commit()

    return {'message': 'User deleted', 'user_id': user_id}