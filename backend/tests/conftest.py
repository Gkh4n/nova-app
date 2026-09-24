import gc
import os
import time
from pathlib import Path

TEST_DB = Path(__file__).with_name("test_nova.db")


def _remove_test_db() -> None:
    """Best-effort cleanup for Windows, where SQLite may release the file a little late."""
    if not TEST_DB.exists():
        return
    for _ in range(20):
        try:
            TEST_DB.unlink()
            return
        except PermissionError:
            gc.collect()
            time.sleep(0.1)
    # Test cleanup must never turn an otherwise successful test run into a failure.
    # The next pytest process will retry before creating the database.


_remove_test_db()
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB.as_posix()}"
os.environ["NOVA_SECRET_KEY"] = "nova-test-secret"
os.environ["NOVA_DEV_RETURN_RESET_TOKEN"] = "1"


def pytest_sessionfinish(session, exitstatus):
    try:
        from app.database.session import engine
        engine.dispose()
    except Exception:
        pass
    gc.collect()
    _remove_test_db()
