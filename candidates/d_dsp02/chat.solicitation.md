# Solicitation record — d_dsp02 / chat

Records how this submission was obtained. Written because the prior five
submissions for this task have no such record: a pinned prompt with no
solicitation record moves the reproducibility gap up one level rather than
closing it.

## Derivable — filled, do not edit

    submission_file:      candidates/d_dsp02/chat.sv
    submission_sha256:    d9643ea68fd0f4a16808694451b14a3b51014cb796224620d1b4055d7589ea68
    paste_md_sha256:      1723099c938b9c2cc007cc992a5f825fd9f028ae9bb5249e9514792d6abb8e71
    task_text_hash:       530f3e4189421457
    task:                 d_dsp02 / fp32_fma_ii1
    spec_iface_sha256:    be47cc9026a32a2ad980208d9453566ec2d5d6cd7e1df90ce2b5e1f68208f4db

The task_text_hash covers spec/fp32_fma_ii1_iface.sv AND probe/PASTE.md
together. paste_md_sha256 pins the literal bytes handed over; task_text_hash
pins the contract they belong to. If a later edit moves the hash, this record
still says which text the model actually saw.

## To fill — Jack

    model_identifier:     TODO   exact versioned string as the vendor reports it,
                                 e.g. "claude-opus-4-6-20260115" or the UI's
                                 stated version. Not "ChatGPT" — the family name
                                 is not a version and will not reproduce.
    date_utc:             TODO   YYYY-MM-DD
    sampling_parameters:  TODO   temperature / top_p / max_tokens / seed, or the
                                 literal "NOT SET" if vendor defaults were used
                                 unmodified. "unknown" is not acceptable; if it
                                 cannot be established, write "not recoverable"
                                 and why.
    preceding_turns:      TODO   "none", or <n> with a one-line summary each.
                                 A prior turn changes what the model was
                                 answering and is the field most likely to make
                                 a result unreproducible.
    tool_access:          TODO   yes / no. If yes: which, and whether invoked.
    transport:            TODO   web UI paste / API / other, plus any
                                 reformatting applied in transit.
    notes:                TODO   anything that would change how the answer is
                                 read. "none" is a valid answer.
