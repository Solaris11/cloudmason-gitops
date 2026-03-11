import json
import logging
from typing import Callable, Awaitable
from aio_pika import connect_robust, ExchangeType
from aio_pika.abc import AbstractIncomingMessage, AbstractRobustConnection, AbstractChannel

logger = logging.getLogger(__name__)

class EventConsumer:
    """
    Asynchronous RabbitMQ consumer used by the 14 CloudMason microservices
    and 1 background worker to listen for domain events.
    """
    def __init__(self, amqp_url: str, exchange_name: str = "cloudmason.events"):
        self.amqp_url = amqp_url
        self.exchange_name = exchange_name
        self.connection: AbstractRobustConnection | None = None
        self.channel: AbstractChannel | None = None

    async def connect(self) -> None:
        """
        Establishes a robust connection to RabbitMQ.
        Automatically reconnects if the broker restarts or connection drops.
        """
        try:
            # Use local variables to satisfy strict type checkers (Pylance)
            conn = await connect_robust(self.amqp_url)
            chan = await conn.channel()

            # Set prefetch count to 1 to ensure fair dispatch across multiple workers
            await chan.set_qos(prefetch_count=1)

            # Ensure the topic exchange exists
            await chan.declare_exchange(
                name=self.exchange_name,
                type=ExchangeType.TOPIC,
                durable=True
            )

            # Assign to instance variables only after successful creation
            self.connection = conn
            self.channel = chan
            logger.info(f"Consumer successfully connected to RabbitMQ exchange: {self.exchange_name}")
        except Exception as e:
            logger.error(f"Consumer failed to connect to RabbitMQ at {self.amqp_url}: {str(e)}")
            raise

    async def start_consuming(
        self,
        queue_name: str,
        routing_key: str,
        callback: Callable[[dict], Awaitable[None]]
    ) -> None:
        """
        Binds a queue to the exchange using the provided routing key and starts listening.
        """
        if not self.channel or self.channel.is_closed:
            raise RuntimeError("Cannot start consuming: RabbitMQ channel is not open. Call connect() first.")

        # Declare a durable queue so messages aren't lost if the consumer service restarts
        queue = await self.channel.declare_queue(queue_name, durable=True)

        # Bind the queue to the exchange
        exchange = await self.channel.get_exchange(self.exchange_name)
        await queue.bind(exchange, routing_key=routing_key)

        logger.info(f"Started consuming from queue '{queue_name}' with routing key '{routing_key}'")

        async def process_message(message: AbstractIncomingMessage) -> None:
            """Internal wrapper to handle message acknowledgement and error handling."""
            async with message.process():
                try:
                    payload = json.loads(message.body.decode())
                    logger.debug(f"Received message ID: {message.message_id}")
                    await callback(payload)
                except json.JSONDecodeError as e:
                    logger.error(f"Failed to decode message payload: {str(e)}")
                    raise
                except Exception as e:
                    logger.error(f"Error processing message in callback: {str(e)}")
                    raise

        # Start consuming messages
        await queue.consume(process_message)

    async def close(self) -> None:
        """Gracefully closes the RabbitMQ connection."""
        if self.connection and not self.connection.is_closed:
            await self.connection.close()
            logger.info("Consumer RabbitMQ connection closed.")
