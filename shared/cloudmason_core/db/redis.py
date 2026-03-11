import logging
from typing import Optional
from redis.asyncio import Redis, from_url

logger = logging.getLogger(__name__)

class RedisManager:
    """
    Asynchronous Redis connection manager for CloudMason microservices.
    Used for high-speed caching, session management, and rate limiting
    across the 14 microservices and background worker.
    """
    def __init__(self, redis_url: str):
        """
        Args:
            redis_url (str): Redis connection string (e.g., redis://:password@host:6379/0)
        """
        self.redis_url = redis_url
        self.client: Optional[Redis] = None

    async def connect(self) -> None:
        """
        Initializes the async Redis client pool and verifies the connection.
        decode_responses=True ensures we get Python strings back instead of bytes.
        """
        try:
            # Use a local variable to satisfy the type checker before assignment
            client = from_url(self.redis_url, decode_responses=True)

            # The redis-py library type stubs incorrectly mark ping() as returning a synchronous bool
            # instead of an Awaitable[bool]. We use type: ignore to bypass this false positive.
            await client.ping()  # type: ignore

            self.client = client
            logger.info("Successfully initialized Redis connection pool and pinged server.")
        except Exception as e:
            logger.error(f"Failed to connect to Redis at {self.redis_url}: {str(e)}")
            raise

    def get_client(self) -> Redis:
        """
        Returns the active Redis client instance for direct operations.

        Returns:
            Redis: The async Redis client.
        """
        if self.client is None:
            raise RuntimeError("Redis client is not initialized. Call connect() first.")

        return self.client

    async def close(self) -> None:
        """
        Gracefully closes the Redis connection pool.
        Should be called during application shutdown.
        """
        if self.client:
            await self.client.aclose()  # type: ignore # aclose() is the modern way to close async redis
            logger.info("Redis connection closed.")
