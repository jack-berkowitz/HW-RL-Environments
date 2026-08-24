# Staging area for the four shared documents

Peers append blocks here; the owner lands them verbatim. See
`CONVENTIONS.md` → *The four shared documents have one writer*.

One file per (shared document, agent):

    inbox/TASK_CATALOG.md.agent3.md
    inbox/FINDINGS.md.agent2.md
    inbox/RULES.md.agent3.md
    inbox/CONVENTIONS.md.agent2.md

Every block opens with `<!-- author: agentN -->`. Blocks are moved into the
shared file unchanged, author line included. A block that fails
`check_rule_linkage.py` or `check_linkage_tree.sh` is returned to its author
rather than repaired here.
