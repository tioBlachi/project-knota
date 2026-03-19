from typing import Annotated

from fastapi import FastAPI, Depends, Query
from sqlmodel import Session, select

from app.db import get_session
from app.models.address import Address

app = FastAPI()


@app.get("/addresses/autocomplete")
def autocomplete_addresses(
    q: Annotated[str, Query(min_length=1)],
    session: Annotated[Session, Depends(get_session)],
    limit: Annotated[int, Query(le=20)] = 10,
):
    query = q.strip().upper()

    if not query:
        return []

    statement = (
        select(Address.full_address)
        .where(Address.full_address.startswith(query))
        .limit(limit)
    )

    results = session.exec(statement).all()
    return results