"""
Router for HTTP requests that are relevant to user CRUD operations
"""
from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.encoders import jsonable_encoder
from sqlmodel import Session, select

from app.db import get_session, engine
from app.models.user import User, UserCreate, UserPublic, UserUpdate
from app.core.security import hash_password, verify_password, create_access_token, get_current_user
from app.services.login_rate_limiter import login_limiter

user_router = APIRouter(prefix="/user", tags=["users"])


@user_router.get('/me', response_model=UserPublic)
def get_user(current_user: Annotated[User, Depends(get_current_user)], session: Session = Depends(get_session)):
    return current_user


@user_router.post("/", response_model=UserPublic, status_code=status.HTTP_201_CREATED)
def create_user(user_in: UserCreate, session: Session = Depends(get_session)):
    """
    Creates a user using the UserCreate class. Checks if email already exists in the database
    If so, raises an HTTPException. If the email is unique, the password is hashed before storage
    into the database. Returns the UserPublic that does not contain their password.
    """

    if session.exec(select(User).where(User.email == user_in.email)).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with that email already exists",
        )
    
    user_data = user_in.model_dump()

    pt_password = user_data.pop('password')
    user_data['hashed_password'] = hash_password(pt_password)

    new_user = User.model_validate(user_data)

    session.add(new_user)
    session.commit()
    session.refresh(new_user)

    return new_user


@user_router.patch('/{user_id}/', response_model=UserPublic)
def update_user(
    user_id: UUID,
    user_data: UserUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Session = Depends(get_session),
):
    """Updates only the values given in the request body, if the user exists in the database. Otherwise, a 404 User 
    Not Found error is returned. Rehashes the new password (if given), checks if the email 
    already exists (to prevent multiple accounts patching the same email to an account after creation). User is then
    updated in the database
    """
    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Forbidden')
    
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail='User not found')
    
    user_data_dump = user_data.model_dump(exclude_unset=True)

    if 'password' in user_data_dump:
        pw = user_data_dump.pop('password')
        user_data_dump['hashed_password'] = hash_password(pw)

    if 'email' in user_data_dump:
        existing_user = session.exec(
            select(User).where(User.email == user_data_dump['email'], User.id != user_id)
        ).first()
        if existing_user:
            raise HTTPException(status_code=400, detail='Email already in use')

    user.sqlmodel_update(user_data_dump)

    session.add(user)
    session.commit()
    session.refresh(user)

    user_data = jsonable_encoder(user)

    return user_data


@user_router.post('/login')
def login_user(form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
               session: Session = Depends(get_session)):
    identifier = form_data.username.strip().lower()
    login_limiter.raise_if_blocked(identifier)

    user = session.exec(
        select(User).where(User.email == identifier)
    ).first()

    if not user or not verify_password(form_data.password, user.hashed_password):
        login_limiter.record_failure(identifier)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Invalid credentials')

    login_limiter.clear(identifier)
    access_token = create_access_token(data={'sub': str(user.id)})
    
    return {
        'access_token': access_token,
        'token_type': 'bearer'
        }


@user_router.delete('/{user_id}/')
def delete_user(user_id: UUID,
                current_user: Annotated[User, Depends(get_current_user)],
                session: Session = Depends(get_session)):
    if current_user.id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Forbidden')
    
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(status_code=404, detail='User does not exist')

    session.delete(user)
    session.commit()

    return {'message': 'User deleted', 'user_id': user_id}
