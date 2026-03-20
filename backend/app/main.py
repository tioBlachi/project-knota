from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.db import create_db_and_tables
from app.routes.addr_router import addr_router
from app.routes.user_router import user_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield

    print('The applicaiton shutdown')

app = FastAPI(lifespan=lifespan)


app.include_router(addr_router)
app.include_router(user_router)