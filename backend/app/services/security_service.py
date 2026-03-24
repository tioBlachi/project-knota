# from fastapi.security import OAuth2PasswordBearer
# from jose import JWTError

# oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# def get_current_user(token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)):
#     try:
#         payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
#         user_id: str = payload.get("sub")
#         if user_id is None:
#             raise HTTPException(status_code=401, detail="Invalid token")
#     except JWTError:
#         raise HTTPException(status_code=401, detail="Invalid token")
        
#     user = session.get(User, int(user_id))
#     if not user:
#         raise HTTPException(status_code=401, detail="User not found")
#     return user
