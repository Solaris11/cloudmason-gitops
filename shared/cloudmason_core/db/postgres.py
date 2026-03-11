import logging
from typing import Optional, AsyncGenerator
from contextlib import asynccontextmanager
import asyncpg
from asyncpg.pool import PoolConnectionProxy

logger = logging.getLogger(__name__)

class PostgresManager:
    """
    Asynchronous PostgreSQL connection pool manager for CloudMason microservices.
    Handles efficient connection pooling for high-concurrency domains like
    Auth, Commerce, Workflow, and User Operations.
    """
    def __init__(self, dsn: str):
        """
        Args:
            dsn (str): Data Source Name (e.g., postgresql://user:pass@host:5432/dbname)
        """
        self.dsn = dsn
        self.pool: Optional[asyncpg.Pool] = None

    async def connect(self, min_size: int = 1, max_size: int = 10) -> None:
        """
        Initializes the connection pool. Should be called during application startup.

        Args:
            min_size (int): Minimum number of connections to keep in the pool.
            max_size (int): Maximum number of connections to allow in the pool.
        """
        try:
            self.pool = await asyncpg.create_pool(
                dsn=self.dsn,
                min_size=min_size,
                max_size=max_size,
            )
            logger.info("Successfully initialized PostgreSQL connection pool.")
        except Exception as e:
            logger.error(f"Failed to initialize PostgreSQL connection pool: {str(e)}")
            raise

    @asynccontextmanager
    async def acquire(self) -> AsyncGenerator[PoolConnectionProxy, None]:
        """
        Safely acquires a connection from the pool and releases it after use.
        Usage:
            async with pg_manager.acquire() as conn:
                await conn.fetch("SELECT * FROM users")
        """
        if not self.pool:
            raise RuntimeError("PostgreSQL pool is not initialized. Call connect() first.")

        # Borrow a connection from the pool
        conn = await self.pool.acquire()
        try:
            yield conn
        finally:
            # Always return the connection to the pool, even if an error occurs
            await self.pool.release(conn)

    async def close(self) -> None:
        """
        Gracefully closes all connections in the pool.
        Should be called during application shutdown.
        """
        if self.pool:
            await self.pool.close()
            logger.info("PostgreSQL connection pool closed.")
