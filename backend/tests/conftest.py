"""Shared fixtures.

The API tests run against a minimal FastAPI app that mounts only the auth and
quiz routers, backed by a throwaway in-memory SQLite database. This avoids
importing app.main (which loads the OCR + RAG models at import time) and keeps
every test isolated -- each test gets a fresh, empty database.
"""

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.auth import router as auth_router
from app.api.quiz import router as quiz_router
from app.database.db import Base, get_db

# A valid registration payload reused across tests; individual tests override
# fields as needed.
SAMPLE_USER = {
    "email": "student@example.com",
    "password": "password123",
    "full_name": "Sample Student",
    "section": "STEM-A",
}


@pytest.fixture
def client():
    """A TestClient over a fresh in-memory DB, with only the auth + quiz routers.

    StaticPool keeps the single in-memory connection alive across requests (a
    plain in-memory SQLite would otherwise get a new, empty database per
    connection). get_db is overridden so the app and the test share that DB.
    """
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app = FastAPI()
    app.include_router(auth_router)
    app.include_router(quiz_router)
    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    Base.metadata.drop_all(bind=engine)
    engine.dispose()


@pytest.fixture
def auth_headers(client):
    """Register + log in SAMPLE_USER and return the Authorization header dict."""
    client.post("/auth/register", json=SAMPLE_USER)
    token = client.post(
        "/auth/login",
        json={"email": SAMPLE_USER["email"], "password": SAMPLE_USER["password"]},
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
