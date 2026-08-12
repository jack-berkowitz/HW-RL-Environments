"""
Turning a model's chat response into a file the compiler will accept.

Models answer with prose around fenced code, sometimes several blocks (a helper
module, a usage example, a "here is the buggy version" contrast). Picking the
wrong block produces a compile error that looks like a model failure but is
really an extraction failure, so this is deliberately conservative: it prefers
the block that actually declares the requested module, and it keeps any helper
modules that came with it.
"""

from __future__ import annotations

import re

FENCE_RE = re.compile(
    r"```[ \t]*(?:systemverilog|verilog|sv|SystemVerilog|Verilog)?[ \t]*\r?\n(.*?)```",
    re.S,
)


def _declares(text: str, module: str) -> bool:
    return re.search(rf"^\s*module\s+{re.escape(module)}\b", text, re.M) is not None


def _has_any_module(text: str) -> bool:
    return re.search(r"^\s*module\s+\w+", text, re.M) is not None


def extract_module(response: str, module: str) -> str | None:
    """
    Pull the SystemVerilog source for `module` out of a chat response.

    Returns None when nothing plausibly containing the module can be found --
    the caller should record that as an extraction failure distinct from a
    compile error, since the two have completely different fixes.
    """
    if not response or not response.strip():
        return None

    blocks = [b.strip() for b in FENCE_RE.findall(response) if b.strip()]

    # 1. A fenced block that declares the requested module.
    named = [b for b in blocks if _declares(b, module)]
    if named:
        # Concatenate rather than picking one: a model that puts a helper module
        # in its own fence still needs both to elaborate. Later blocks that
        # re-declare the same module are dropped as they are usually an
        # "alternative version" the prose already discarded.
        out, seen_target = [], False
        for b in blocks:
            if _declares(b, module):
                if seen_target:
                    continue
                seen_target = True
                out.append(b)
            elif _has_any_module(b):
                out.append(b)
        return "\n\n".join(out)

    # 2. No fence declares it, but the raw response does -- model skipped fences.
    if _declares(response, module):
        return response.strip()

    # 3. A single fenced block with some module in it: the model likely renamed
    #    it. Hand it over and let the compiler reject it; that is a genuine
    #    interface-compliance failure and should be scored as one.
    if len(blocks) == 1 and _has_any_module(blocks[0]):
        return blocks[0]

    return None


PROMPT_TEMPLATE = """\
Implement the SystemVerilog module specified below.

Requirements:
- Match the module name, parameter names, and port list in the specification \
EXACTLY. It is instantiated by name against a fixed testbench.
- Implement the full behaviour described in the header comments.
- The design must be synthesizable RTL.
- Reply with the complete module in a single ```systemverilog code block. \
Do not include a testbench.

--- SPECIFICATION ({module}_iface.sv) ---
{spec}
"""


# Markers that must never reach a model, checked against the spec text.
#
# Note "testbench" is deliberately absent: the specs describe the contract in
# terms of what the testbench will drive, and the template itself tells the model
# one exists. Naming the grader is not a leak. Quoting it is -- these are the
# strings that only appear on the grading side of the wall.
_LEAKS = ("TEST_RESULT", "_tb.", "_tb ", "golden_mem", "mem_stub",
          "reference_solutions")


class PromptLeak(AssertionError):
    """The assembled prompt contained grading material."""


def build_prompt(module: str, spec: str) -> str:
    """
    The task prompt. The interface file is the entire problem statement.

    The leak check is cheap and runs on every sample rather than once in a test,
    because the failure it guards against is silent: a prompt that quotes the
    testbench still produces plausible-looking results, just meaningless ones.
    """
    for leak in _LEAKS:
        if leak in spec:
            raise PromptLeak(
                f"spec for '{module}' contains grading material ({leak!r}); "
                f"the prompt must come from interfaces/ alone"
            )
    return PROMPT_TEMPLATE.format(module=module, spec=spec)
