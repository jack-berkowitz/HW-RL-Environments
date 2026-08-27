"""Discovery of the current ``domains/`` benchmark tasks."""

from __future__ import annotations

import hashlib
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


class TaskDiscoveryError(RuntimeError):
    pass


@dataclass(frozen=True)
class DomainTask:
    task_id: str
    kind: str
    module: str
    directory: Path
    prompt_path: Path
    prompt_bytes: bytes
    prompt_text: str
    prompt_sha256: str
    task_text_hash: str


def _yaml_scalar(text: str, key: str, *, indented: bool = False) -> str | None:
    prefix = r"^\s+" if indented else r"^"
    match = re.search(prefix + re.escape(key) + r":\s*(.+?)\s*$", text, re.M)
    if not match:
        return None
    return match.group(1).split("#", 1)[0].strip().strip("'\"")


def _task_text_hash(task_dir: Path, repo_root: Path) -> str:
    script = repo_root / "scripts" / "task_text_hash.py"
    result = subprocess.run(
        [sys.executable, str(script), str(task_dir)],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise TaskDiscoveryError(f"cannot hash {task_dir.name}: {detail}")
    return result.stdout.splitlines()[0].strip()


def discover_tasks(repo_root: Path = REPO_ROOT) -> list[DomainTask]:
    tasks: list[DomainTask] = []
    for prompt_path in sorted(repo_root.glob("domains/*/*/*/probe/PASTE.md")):
        task_dir = prompt_path.parent.parent
        metadata_path = task_dir / "task.yaml"
        if not metadata_path.is_file():
            # Prompt-only directories can be retained for withdrawn tasks. A
            # task.yaml file is the explicit registration boundary for sweeps.
            continue
        metadata = metadata_path.read_text(encoding="utf-8")
        task_id = _yaml_scalar(metadata, "id")
        kind = _yaml_scalar(metadata, "type")
        module = _yaml_scalar(metadata, "module")
        if not task_id or kind not in {"design", "verification"} or not module:
            raise TaskDiscoveryError(f"incomplete identity metadata in {metadata_path}")
        target = module if kind == "design" else _yaml_scalar(
            metadata, "tb_module", indented=True
        )
        if not target:
            raise TaskDiscoveryError(f"{metadata_path} has no harness.tb_module")
        prompt_bytes = prompt_path.read_bytes()
        try:
            prompt_text = prompt_bytes.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise TaskDiscoveryError(f"{prompt_path} is not UTF-8: {exc}") from exc
        tasks.append(DomainTask(
            task_id=task_id,
            kind=kind,
            module=target,
            directory=task_dir,
            prompt_path=prompt_path,
            prompt_bytes=prompt_bytes,
            prompt_text=prompt_text,
            prompt_sha256=hashlib.sha256(prompt_bytes).hexdigest(),
            task_text_hash=_task_text_hash(task_dir, repo_root),
        ))
    ids = [task.task_id for task in tasks]
    if len(set(ids)) != len(ids):
        raise TaskDiscoveryError("duplicate task IDs in domains/")
    return tasks


def select_tasks(tasks: list[DomainTask], names: list[str]) -> list[DomainTask]:
    if not names or names == ["all"]:
        return tasks
    by_id = {task.task_id: task for task in tasks}
    unknown = [name for name in names if name not in by_id]
    if unknown:
        raise ValueError(
            f"unknown or unpackaged task(s): {', '.join(unknown)}; "
            f"available: {', '.join(by_id)}"
        )
    return [by_id[name] for name in names]
