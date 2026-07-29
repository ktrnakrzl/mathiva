"""add password reset tokens

Revision ID: b7d9f2a3c001
Revises: a05f356fd3cc
Create Date: 2026-07-30 01:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b7d9f2a3c001"
down_revision: Union[str, Sequence[str], None] = "a05f356fd3cc"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "password_reset_tokens",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("used_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    with op.batch_alter_table("password_reset_tokens", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_password_reset_tokens_created_at"),
            ["created_at"],
            unique=False,
        )
        batch_op.create_index(
            batch_op.f("ix_password_reset_tokens_expires_at"),
            ["expires_at"],
            unique=False,
        )
        batch_op.create_index(
            batch_op.f("ix_password_reset_tokens_id"),
            ["id"],
            unique=False,
        )
        batch_op.create_index(
            batch_op.f("ix_password_reset_tokens_token_hash"),
            ["token_hash"],
            unique=True,
        )
        batch_op.create_index(
            batch_op.f("ix_password_reset_tokens_user_id"),
            ["user_id"],
            unique=False,
        )


def downgrade() -> None:
    with op.batch_alter_table("password_reset_tokens", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_password_reset_tokens_user_id"))
        batch_op.drop_index(batch_op.f("ix_password_reset_tokens_token_hash"))
        batch_op.drop_index(batch_op.f("ix_password_reset_tokens_id"))
        batch_op.drop_index(batch_op.f("ix_password_reset_tokens_expires_at"))
        batch_op.drop_index(batch_op.f("ix_password_reset_tokens_created_at"))
    op.drop_table("password_reset_tokens")
