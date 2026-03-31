from sqlmodel import SQLModel, Session, create_engine
from app.config import settings

import app.models


DATABASE_URL: str = settings.DATABASE_URL

if not DATABASE_URL:
    raise ValueError('DATABASE_URL in not set')

engine = create_engine(DATABASE_URL, echo=settings.SQL_ECHO)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
