from collections import defaultdict, deque
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status

from app.config import settings


@dataclass
class _LoginAttemptState:
    failures: deque[datetime] = field(default_factory=deque)
    blocked_until: datetime | None = None


class LoginRateLimiter:
    def __init__(
        self,
        max_attempts: int,
        window_seconds: int,
        lockout_seconds: int,
    ) -> None:
        self.max_attempts = max_attempts
        self.window = timedelta(seconds=window_seconds)
        self.lockout = timedelta(seconds=lockout_seconds)
        self._attempts: dict[str, _LoginAttemptState] = defaultdict(
            _LoginAttemptState
        )

    def _now(self) -> datetime:
        return datetime.now(timezone.utc)

    def _prune(self, state: _LoginAttemptState, now: datetime) -> None:
        cutoff = now - self.window
        while state.failures and state.failures[0] < cutoff:
            state.failures.popleft()

        if state.blocked_until is not None and state.blocked_until <= now:
            state.blocked_until = None

    def raise_if_blocked(self, identifier: str) -> None:
        now = self._now()
        state = self._attempts[identifier]
        self._prune(state, now)

        if state.blocked_until is not None:
            retry_after = max(
                1,
                int((state.blocked_until - now).total_seconds()),
            )
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail='Too many login attempts. Please try again later.',
                headers={'Retry-After': str(retry_after)},
            )

    def record_failure(self, identifier: str) -> None:
        now = self._now()
        state = self._attempts[identifier]
        self._prune(state, now)
        state.failures.append(now)

        if len(state.failures) >= self.max_attempts:
            state.blocked_until = now + self.lockout
            state.failures.clear()

    def clear(self, identifier: str) -> None:
        self._attempts.pop(identifier, None)


login_limiter = LoginRateLimiter(
    max_attempts=settings.LOGIN_MAX_ATTEMPTS,
    window_seconds=settings.LOGIN_WINDOW_SECONDS,
    lockout_seconds=settings.LOGIN_LOCKOUT_SECONDS,
)
