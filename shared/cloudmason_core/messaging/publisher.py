import json
import logging
from aio_pika import Message, DeliveryMode, ExchangeType, connect_robust
from aio_pika.abc import AbstractRobustConnection, AbstractChannel
from cloudmason_core.events.base import BaseEvent

logger = logging.getLogger(__name__)

class EventPublisher:
    """
    Asynchronous RabbitMQ publisher used by CloudMason microservices to
    broadcast events to the central message broker.
    """
    def __init__(self, amqp_url: str, exchange_name: str = "cloudmason.events"):
        self.amqp_url = amqp_url
        self.exchange_name = exchange_name
        self.connection: AbstractRobustConnection | None = None
        self.channel: AbstractChannel | None = None

    async def connect(self) -> None:
        """
        Establishes a robust connection to RabbitMQ.
        Automatically reconnects if the connection drops.
        """
        try:
            # Use local variables to satisfy strict type checkers (Pylance)
            conn = await connect_robust(self.amqp_url)
            chan = await conn.channel()

            # Ensure the exchange exists (Topic exchange allows complex routing keys)
            await chan.declare_exchange(
                name=self.exchange_name,
                type=ExchangeType.TOPIC,
                durable=True
            )

            # Assign to instance variables only after successful creation
            self.connection = conn
            self.channel = chan
            logger.info(f"Successfully connected to RabbitMQ and declared exchange: {self.exchange_name}")
        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ at {self.amqp_url}: {str(e)}")
            raise

    async def publish(self, event: BaseEvent, routing_key: str) -> None:
        """
        Serializes a Pydantic event model to JSON and publishes it to RabbitMQ.
        """
        if not self.channel or self.channel.is_closed:
            raise RuntimeError("Cannot publish event: RabbitMQ channel is not open. Call connect() first.")

        # Convert the immutable Pydantic model to a JSON string
        event_payload = event.model_dump_json()

        message = Message(
            body=event_payload.encode(),
            delivery_mode=DeliveryMode.PERSISTENT,
            content_type="application/json",
            correlation_id=str(event.correlation_id),
            message_id=str(event.event_id)
        )

        exchange = await self.channel.get_exchange(self.exchange_name)

        await exchange.publish(message, routing_key=routing_key)
        logger.debug(f"Published event {event.event_type} to {routing_key} with ID {event.event_id}")

    async def close(self) -> None:
        """Gracefully closes the RabbitMQ connection."""
        if self.connection and not self.connection.is_closed:
            await self.connection.close()
            logger.info("RabbitMQ connection closed.")
