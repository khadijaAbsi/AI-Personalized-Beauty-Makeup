
from uuid import uuid4

import pytest

from app.domain.entities.analysis_job import (
    AnalysisJob,
    AnalysisStatus,
)


class TestAnalysisJob:

    def test_new_job_is_pending(self):
        job = AnalysisJob(user_id=uuid4())

        assert job.status == AnalysisStatus.PENDING

    def test_job_lifecycle(self):
        job = AnalysisJob(user_id=uuid4())

        job.start()
        assert job.status == AnalysisStatus.PROCESSING

        job.complete()
        assert job.status == AnalysisStatus.COMPLETED

    def test_job_can_fail(self):
        job = AnalysisJob(user_id=uuid4())

        job.start()
        job.fail()

        assert job.status == AnalysisStatus.FAILED

    def test_cannot_complete_pending_job(self):
        job = AnalysisJob(user_id=uuid4())

        with pytest.raises(ValueError):
            job.complete()

    def test_jobs_have_unique_ids(self):
        user_id = uuid4()

        first = AnalysisJob(user_id=user_id)
        second = AnalysisJob(user_id=user_id)

        assert first.id != second.id
