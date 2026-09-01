# d_ca06 — concurrent multi-port queue

Submissions go here as `chat.sv`, `claude.sv`, `gemini.sv`, each a complete
`module queue` matching the port list in
`domains/comp_arch/design/d_ca06_multiport_queue/spec/multiport_queue_iface.sv`.

NOT YET SOLICITED. The pinned period is not set — the reference Fmax sweep has
not run — and the pin rule requires it to be stated in the spec before models
are prompted. Prompting now would produce submissions that were told the
frequency target was unknown, which is the defect that made d_ai04's floor
question unanswerable.
