from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

from app.routes.addr_router import addr_router
from app.routes.auth_router import auth_router
from app.routes.report_router import report_router
from app.routes.user_router import user_router
from app.routes.appointment_router import appointment_router


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(addr_router)
app.include_router(auth_router)
app.include_router(report_router)
app.include_router(user_router)
app.include_router(appointment_router)


@app.get("/health")
def health_check():
    return {"status": "ok"}


handler = Mangum(app, lifespan="off")
