#!/usr/bin/env python3
"""
Access Policies - the Security Agent's policy source

Loads "resource.action: policy" lines from policies/access.policy and
answers which policy governs a request. The policy is a formal expression
that engines/meta.sh -a decides against the request's facts.

Without this file the Security Agent had no policy source at all: it built
a "policy" from the request's own context flags, which can never contradict
the request.

COPYRIGHT 2025 TODOMODO.IO AGENCY LLC - ALL RIGHTS RESERVED
"""

import logging
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

logger = logging.getLogger("access_policies")

POLICIES_DIR = Path(__file__).parent / "policies"
DEFAULT_POLICY_FILE = POLICIES_DIR / "access.policy"

# resource.action: expression   ("*" wildcards allowed on either side)
_LINE = re.compile(r'^(\*|[A-Za-z][A-Za-z0-9_]*)\.(\*|[A-Za-z][A-Za-z0-9_]*)\s*:\s*(.+)$')

# What the engines accept. The expression is handed to a shell engine, so
# anything outside the formula alphabet is refused at load time.
_EXPRESSION = re.compile(r'^[A-Za-z0-9_= ()¬∧∨→↔⊤⊥□◇]+$')


@dataclass(frozen=True)
class Policy:
    resource: str
    action: str
    expression: str
    source: str  # file:line

    @property
    def key(self) -> str:
        return f"{self.resource}.{self.action}"


class PolicyStore:
    """Policies keyed by (resource, action), with wildcard fallback."""

    def __init__(self, path: Optional[Path] = None):
        self.path = Path(path) if path else DEFAULT_POLICY_FILE
        self.policies: dict[tuple[str, str], Policy] = {}
        self.rejected: list[str] = []
        self._load()

    def _load(self) -> None:
        if not self.path.exists():
            logger.warning(f"Policy file not found: {self.path} (every request will be denied)")
            return
        with open(self.path) as f:
            for lineno, raw in enumerate(f, 1):
                line = raw.split('#', 1)[0].strip()
                if not line:
                    continue
                match = _LINE.match(line)
                where = f"{self.path.name}:{lineno}"
                if not match:
                    self.rejected.append(where)
                    logger.warning(f"{where}: not a policy line, ignored: {line}")
                    continue
                resource, action, expression = match.group(1), match.group(2), match.group(3).strip()
                if not _EXPRESSION.match(expression):
                    self.rejected.append(where)
                    logger.warning(f"{where}: expression contains characters outside the "
                                   f"formula alphabet, ignored: {expression}")
                    continue
                key = (resource, action)
                if key in self.policies:
                    logger.warning(f"{where}: duplicate policy for {resource}.{action}, "
                                   f"replaces {self.policies[key].source}")
                self.policies[key] = Policy(resource, action, expression, where)
        logger.info(f"Loaded {len(self.policies)} access policies from {self.path.name}")

    def lookup(self, resource: str, action: str) -> Optional[Policy]:
        """Most specific match: exact, resource.*, *.action, *.*; None if none."""
        for key in ((resource, action), (resource, "*"), ("*", action), ("*", "*")):
            if key in self.policies:
                return self.policies[key]
        return None

    def __len__(self) -> int:
        return len(self.policies)


_default_store: Optional[PolicyStore] = None


def get_policy_store() -> PolicyStore:
    global _default_store
    if _default_store is None:
        _default_store = PolicyStore()
    return _default_store


if __name__ == "__main__":
    store = PolicyStore()
    print(f"{len(store)} policies from {store.path}")
    for (resource, action), policy in sorted(store.policies.items()):
        print(f"  {resource}.{action}: {policy.expression}")
    if store.rejected:
        print(f"rejected lines: {store.rejected}")
