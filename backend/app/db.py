import os
from pathlib import Path
from dotenv import load_dotenv

from sqlmodel import SQLModel, Session, create_engine

from app.models.address import Address
from app.models.user import User

ROOT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(ROOT_DIR / '.env')

DATABASE_URL: str = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError('DATABASE_URL in not set')

engine = create_engine(DATABASE_URL, echo=True)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session