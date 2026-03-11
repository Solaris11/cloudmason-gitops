from datetime import datetime, timezone
from uuid import UUID, uuid4
from pydantic import BaseModel, Field

class BaseEvent(BaseModel):
    """
    Base Event schema used by the 14 microservices and 1 background worker
    in the CloudMason platform for RabbitMQ messaging.
    All domain events must inherit from this class.
    """
    event_id: UUID = Field(
        default_factory=uuid4,
        description="Unique identifier for the event"
    )
    correlation_id: UUID = Field(
        ...,
        description="Shared tracing ID to track requests across the 14 services (Distributed Tracing)"
    )
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Timestamp of when the event occurred (UTC)"
    )
    source_service: str = Field(
        ...,
        description="Name of the service emitting the event (e.g., identity-service, core-ai-service)"
    )
    event_type: str = Field(
        ...,
        description="Technical type of the event (e.g., UserCreated, ArchitectureGenerated)"
    )

    class Config:
        # Events represent facts that happened in the past; they are immutable once created.
        frozen = True
