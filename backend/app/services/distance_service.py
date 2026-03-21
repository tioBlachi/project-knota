"""
Service functions related to cached route distances.
"""

import logging
import os

import requests
from fastapi import HTTPException, status
from sqlmodel import Session, select

from app.models.distance import Distance

logger = logging.getLogger(__name__)

GOOGLE_ROUTES_API_KEY = os.getenv("GOOGLE_ROUTES_API_KEY")
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
    if not GOOGLE_ROUTES_API_KEY:
        logger.error("Google Routes API key is not configured")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google Routes API key is not configured",
        )

    logger.info(
        "Calling Google Routes API | origin=%s | destination=%s",
        origin_address,
        destination_address,
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
        "X-Goog-Api-Key": GOOGLE_ROUTES_API_KEY,
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
        logger.exception(
            "Google Routes API request failed | origin=%s | destination=%s",
            origin_address,
            destination_address,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to retrieve distance from Google Routes API",
        ) from exc

    data = response.json()

    if "routes" not in data or not data["routes"]:
        logger.warning(
            "No route returned by Google Routes API | origin=%s | destination=%s | response=%s",
            origin_address,
            destination_address,
            data,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No route found for the provided addresses",
        )

    try:
        one_way_meters = float(data["routes"][0]["distanceMeters"])
    except (KeyError, TypeError, ValueError) as exc:
        logger.exception(
            "Invalid distance data returned by Google Routes API | response=%s",
            data,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Invalid distance data returned by Google Routes API",
        ) from exc

    roundtrip_meters = one_way_meters * 2
    roundtrip_miles = round(convert_meters_to_miles(roundtrip_meters), 2)

    logger.info(
        "Google Routes API success | origin=%s | destination=%s | roundtrip_miles=%s",
        origin_address,
        destination_address,
        roundtrip_miles,
    )

    return roundtrip_miles


def get_or_create_distance(
    session: Session,
    origin_address: str,
    destination_address: str,
) -> Distance:
    """
    Return an existing cached distance row if one exists.
    Otherwise, calculate the roundtrip distance, save it, and return it.
    """
    origin_address = origin_address.strip().lower()
    destination_address = destination_address.strip().lower()

    logger.info(
        "Checking distance cache | origin=%s | destination=%s",
        origin_address,
        destination_address,
    )

    existing_distance = session.exec(
        select(Distance).where(
            Distance.origin_address == origin_address,
            Distance.destination_address == destination_address,
        )
    ).first()

    if existing_distance:
        logger.info(
            "Distance cache hit | distance_id=%s | roundtrip_miles=%s",
            existing_distance.id,
            existing_distance.roundtrip_distance,
        )
        return existing_distance

    logger.info(
        "Distance cache miss | origin=%s | destination=%s",
        origin_address,
        destination_address,
    )

    roundtrip_distance = calculate_roundtrip_distance(
        origin_address=origin_address,
        destination_address=destination_address,
    )

    new_distance = Distance(
        origin_address=origin_address,
        destination_address=destination_address,
        roundtrip_distance=roundtrip_distance,
    )

    session.add(new_distance)
    session.commit()
    session.refresh(new_distance)

    logger.info(
        "Created new cached distance | distance_id=%s | roundtrip_miles=%s",
        new_distance.id,
        new_distance.roundtrip_distance,
    )

    return new_distance