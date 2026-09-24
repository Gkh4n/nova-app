from sqlalchemy import inspect, text

from app.database.session import engine


def _add_column(table: str, column_sql: str, name: str) -> None:
    inspector = inspect(engine)
    if table not in inspector.get_table_names():
        return
    columns = {column["name"] for column in inspector.get_columns(table)}
    if name not in columns:
        with engine.begin() as connection:
            connection.execute(text(f"ALTER TABLE {table} ADD COLUMN {column_sql}"))


def ensure_runtime_schema() -> None:
    # create_all handles all new tables. These ALTERs preserve pre-v1 beta users.
    _add_column("users", "bio VARCHAR(160) NOT NULL DEFAULT ''", "bio")
    _add_column("users", "is_active BOOLEAN NOT NULL DEFAULT 1", "is_active")
    _add_column("users", "token_version INTEGER NOT NULL DEFAULT 0", "token_version")
