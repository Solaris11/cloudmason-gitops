import logging
from typing import Optional
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

logger = logging.getLogger(__name__)

class MongoManager:
    """
    Asynchronous MongoDB connection manager for CloudMason microservices.
    Handles connection pooling internally via Motor for document-heavy
    domains like AI Platform and Communication.
    """
    def __init__(self, uri: str):
        """
        Args:
            uri (str): MongoDB connection string (e.g., mongodb://user:pass@host:27017/)
        """
        self.uri = uri
        self.client: Optional[AsyncIOMotorClient] = None

    async def connect(self) -> None:
        """
        Initializes the MongoDB client and verifies the connection.
        Should be called during application startup.
        Motor automatically manages the connection pool.
        """
        try:
            # Initialize the AsyncIOMotorClient
            self.client = AsyncIOMotorClient(self.uri)

            # Ping the admin database to verify the connection is actually alive
            await self.client.admin.command('ping')

            logger.info("Successfully initialized MongoDB connection pool and pinged server.")
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB at {self.uri}: {str(e)}")
            raise

    def get_database(self, db_name: str) -> AsyncIOMotorDatabase:
        """
        Retrieves a reference to a specific database.

        Args:
            db_name (str): Name of the database to retrieve (e.g., 'core_ai_metadata').

        Returns:
            AsyncIOMotorDatabase: The requested database instance.
        """
        if self.client is None:
            raise RuntimeError("MongoDB client is not initialized. Call connect() first.")

        return self.client.get_database(db_name)

    async def close(self) -> None:
        """
        Closes the MongoDB client connections.
        Should be called during application shutdown.
        """
        if self.client:
            self.client.close()
            logger.info("MongoDB connection closed.")
