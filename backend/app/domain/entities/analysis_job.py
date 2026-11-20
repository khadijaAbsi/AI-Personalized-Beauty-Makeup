
from dataclasses import dataclass, field
from enum import Enum
from uuid import UUID, uuid4


class AnalysisStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class AnalysisJob:
    user_id: UUID
    id: UUID = field(default_factory=uuid4)
    status: AnalysisStatus = AnalysisStatus.PENDING

    def start(self) -> None:
        if self.status != AnalysisStatus.PENDING:
            raise ValueError("Job cannot be started.")
        self.status = AnalysisStatus.PROCESSING

    def complete(self) -> None:
        if self.status != AnalysisStatus.PROCESSING:
            raise ValueError("Job is not processing.")
        self.status = AnalysisStatus.COMPLETED

    def fail(self) -> None:
        if self.status != AnalysisStatus.PROCESSING:
            raise ValueError("Job is not processing.")
        self.status = AnalysisStatus.FAILED
