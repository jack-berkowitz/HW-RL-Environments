"""Grading harness for the HW-RL environments.

Package import is deliberately side-effect free. The retained legacy registry
is documented as non-functional after the tier removal; eagerly importing it
prevented even independent modules such as ``runner.models`` and the current
domain pipeline from starting.
"""

from importlib import import_module

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


def __getattr__(name):
    """Preserve the old convenience exports without eager legacy imports."""
    if name in {"ALL_MODULES", "TASKS", "ParamSet", "Task"}:
        config = import_module(".config", __name__)
        return getattr(config, name)
    if name in {
        "DEFAULT_SIMULATOR", "Outcome", "Score", "check_candidate_source",
        "score", "score_sweep",
    }:
        score_module = import_module(".score", __name__)
        return getattr(score_module, name)
    raise AttributeError(name)
