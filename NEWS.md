# interfacespace 0.1.1

* Decision origin (review item 11). Each bundled register has a new file
  `decision_origin.csv` (`decision`, `proposed_by`, `accepted`,
  `source_file`, `note`) recording who proposed each decision: `A3` (the
  decision-proposal and consistency model), `A4` (the main session model,
  first-round proposals of HLT-C2, HLT-C12 and PA-2.4, confirmed by the
  author) or `A1` (the author changed the A3 proposal or added the item).
  It is derived mechanically by `inst/extdata/decision_origin.py`, which
  matches action, rows and reason of each decision against the proposal
  files, now shipped as `registers/<ID>/00_*.json`. `decisions.csv` is
  unchanged; agent `A4` is appended to `agents.csv` of HLT-C2, HLT-C12 and
  PA-2.4.
* `InterfaceSpace`: new methods `add_decision_origin()`,
  `decision_origin()` and `origin_summary()`; `decisions()` gains the
  columns `proposed_by` and `accepted`; `validate()` reports
  `decision_without_origin`, `origin_unknown_decision` and
  `origin_unknown_agent` once an origin is recorded.
* `read_register()` reads `decision_origin.csv` when present.
* New `decision_origin_summary()`: per study and table, decisions proposed
  by A3 and recorded unchanged, modified by the author, and reversed by a
  later decision (review item 4).
* Per-study counts are unchanged.

# interfacespace 0.1.0

* First release.
* `InterfaceSpace` R6 class: agents, findings, transformations (with the
  rule-12 `partition` flag), claims, relations and append-only decisions;
  computed roots and jointness; `counts()`, `validate()`,
  `joint_display()`, `as_igraph()` and `to_json()`.
* `read_register()` builds a space from a workbook-format CSV register by
  replaying its decisions; `register_counts()` returns per-study and pooled
  counts; `bundled_registers()` locates the ten registers shipped in
  `inst/extdata` (data under CC BY 4.0).
* Vignette "interface-space".
