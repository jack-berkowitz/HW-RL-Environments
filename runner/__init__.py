"""Grading harness for the HW-RL environments."""

from .config import ALL_MODULES, TASKS, ParamSet, Task
# Deliberately NOT importing .models here: it has a __main__ entry point, and a
# package that imports it makes `python3 -m runner.models` warn about double
# import. Use `from runner.models import MODELS`.
from .score import (
    DEFAULT_SIMULATOR,
    Outcome,
    Score,
    check_candidate_source,
    score,
    score_sweep,
)

__all__ = [
    "ALL_MODULES",
    "DEFAULT_SIMULATOR",
    "TASKS",
    "Outcome",
    "ParamSet",
    "Score",
    "Task",
    "check_candidate_source",
    "score",
    "score_sweep",
]
