from typing import Annotated
from fastapi import APIRouter, Query, Depends
from sqlmodel import Session, select

from app.models.address import Address
from app.db import get_session


addr_router = APIRouter(
    prefix='/addresses',
    tags=['addresses']
)

@addr_router.get('/autocomplete', response_model=list)
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
        .where(Address.full_address.ilike(f"%{query}%"))
        .limit(limit)
    )

    results = session.exec(statement).all()
    return results