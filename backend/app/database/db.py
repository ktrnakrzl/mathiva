from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from app.config import settings

# Defaults to a local SQLite file so auth works with zero setup. Swapping to
# Supabase Postgres later is just setting DATABASE_URL in backend/.env --
# the models below don't need to change (pgvector only matters for the
# separate FAISS-storage table, not these).
DATABASE_URL = settings.database_url

# SQLite only allows a connection to be used by the thread that created it;
# FastAPI may serve a request on a different thread than the one that opened
# the connection, so this check has to be disabled for SQLite specifically.
connect_args = {"check_same_thread": False} if settings.is_sqlite else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """FastAPI dependency that yields a DB session and always closes it."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
