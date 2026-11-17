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
