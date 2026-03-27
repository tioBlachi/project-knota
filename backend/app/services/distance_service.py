"""
Service functions related to cached route distances.
"""
import requests

from fastapi import Depends, HTTPException, status
from sqlmodel import Session, select
from sqlalchemy.exc import IntegrityError

from app.db import get_session
from app.models.distance import Distance
from app.config import settings


GOOGLE_API_KEY = settings.GOOGLE_API_KEY
GOOGLE_ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"


def convert_meters_to_miles(meters: float) -> float:
    """
    Convert meters to miles.
    """
    return meters * 0.000621371


def calculate_roundtrip_distance(origin_address: str, destination_address: str) -> float:
    """
    Call the Google Routes API and return the roundtrip distance in miles.
    """
    if not GOOGLE_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google Routes API key is not configured",
        )

    request_body = {
        "origin": {
            "address": origin_address
        },
        "destination": {
            "address": destination_address
        },
        "travelMode": "DRIVE"
    }

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_API_KEY,
        "X-Goog-FieldMask": "routes.distanceMeters"
    }

    try:
        response = requests.post(
            GOOGLE_ROUTES_URL,
            json=request_body,
            headers=headers,
            timeout=10,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to retrieve distance from Google Routes API",
        ) from exc

    data = response.json()

    if "routes" not in data or not data["routes"]:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No route found for the provided addresses",
        )

    try:
        one_way_meters = float(data["routes"][0]["distanceMeters"])
    except (KeyError, TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Invalid distance data returned by Google Routes API",
        ) from exc

    roundtrip_meters = one_way_meters * 2
    roundtrip_miles = round(convert_meters_to_miles(roundtrip_meters), 2)

    return roundtrip_miles


def get_or_create_distance(
    origin_address: str,
    destination_address: str,
    session: Session,
) -> Distance:
    """
    Return an existing cached distance row if one exists.
    Otherwise, calculate the roundtrip distance, save it, and return it.
    """
    addr1 = origin_address.strip().lower()
    addr2 = destination_address.strip().lower()

    clean_origin, clean_dest = sorted([addr1, addr2])

    existing_distance = session.exec(
        select(Distance).where(
            Distance.origin_address == clean_origin,
            Distance.destination_address == clean_dest,
        )
    ).first()

    if existing_distance:
        return existing_distance

    roundtrip_distance = calculate_roundtrip_distance(
        origin_address=clean_origin,
        destination_address=clean_dest,
    )

    new_distance = Distance.model_validate({
        'origin_address': clean_origin,
        'destination_address': clean_dest,
        'roundtrip_distance': roundtrip_distance,
    })
    
    try:
        session.add(new_distance)
        session.commit()
        session.refresh(new_distance)
        return new_distance
    except IntegrityError:
        session.rollback()
        return session.exec(
            select(Distance).where(
                Distance.origin_address == clean_origin,
                Distance.destination_address == clean_dest,
            )
        ).one()
    