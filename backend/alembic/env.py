"""Alembic migration environment for MATHIVA.

Wired to the app's own config and models: the database URL comes from
`app.config.settings` (so migrations hit the same DB the app does -- SQLite in
dev, Postgres/Supabase in production), and `target_metadata` is the app's
`Base.metadata`, so `alembic revision --autogenerate` diffs against the live
models. `render_as_batch=True` keeps ALTERs working on SQLite.
"""

from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool

from alembic import context

# App config + models. Importing models registers every table on Base.metadata.
from app.config import settings
from app.database.db import Base
import app.database.models  # noqa: F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Drive the connection from the app's settings, not the alembic.ini placeholder.
# configparser treats '%' as interpolation syntax, so a URL-encoded password
# (e.g. '%40' for '@') would raise "invalid interpolation syntax". Escape '%' as
# '%%'; configparser un-escapes it back to the real URL when the value is read.
config.set_main_option("sqlalchemy.url", settings.database_url.replace("%", "%%"))

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Emit SQL without a live DB connection (`alembic upgrade --sql`)."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_as_batch=True,
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations against a live DB connection."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            render_as_batch=True,
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
