# interfacespace

Registers of joint qualitative-quantitative claims (interface spaces) for
mixed methods evaluation.

## Purpose

The interface space is the set of joint qualitative-quantitative claims an
evaluation produces. It is kept as a register of findings (qualitative strand
`Q` or quantitative strand `N`), transformations of findings, headline
claims, relations among claims (`backs`, `clashes`, `covers`) and decisions
with reasons. The package provides:

- `InterfaceSpace`, an R6 class over `data.table` tables in which every row
  is born a candidate and status changes only through append-only decisions
  taken by a person, with a written reason;
- computed jointness: a claim is joint when its findings, traced back through
  endorsed transformations to their roots, include at least one `Q` and one
  `N` root (a coding rule 12 transformation, `partition = TRUE`, also makes
  its output a root);
- `read_register()` to read a workbook-format CSV register, replaying its
  decisions in order, and `register_counts()` for per-study and pooled
  counts;
- `validate()`, `joint_display()`, `as_igraph()` and `to_json()`;
- the registers of ten published mixed methods evaluations of public
  services, with the coding protocol and the prompts used to propose rows.

## Installation

```r
# install.packages("remotes")
remotes::install_github("gmontaletti/interfacespace")
```

## Minimal example

```r
library(interfacespace)

x <- InterfaceSpace$new("demo")
x$add_agent("A1", "Analyst", "person")
x$add_agent("A2", "LLM extractor", "model", "model x, prompt v1")
x$add_finding("F1", "Q", "Users describe growing confidence.",
              where_to_check = "Interviews, p. 7", proposed_by = "A2")
x$add_finding("F2", "N", "Confidence scale rises, d = 0.45.",
              where_to_check = "Table 2", proposed_by = "A2")
x$propose_claim("C1", "The service raises confidence.",
                rests_on = c("F1", "F2"), fit = "confirm", proposed_by = "A2")
x$decide(c("F1", "F2", "C1"), "endorse", actor = "A1",
         reason = "Recorded as stated in the abstract and results.")
x$is_joint("C1")
x$joint_display()

# a published register: Woodall et al. (2018)
hlt <- read_register(bundled_registers("HLT-C2"))
hlt$counts()

# per-study and pooled counts of the ten registers
register_counts(bundled_registers(), pooled = TRUE)
```

See `vignette("interface-space")` for the workbook in brief and a worked
register.

## Data and licence

The code is released under the MIT licence (`LICENSE`, `LICENSE.md`).

The data in `inst/extdata` (the ten registers, `screening.csv`, the coding
protocol `00_protocol.md` and the prompt files) are released under the
Creative Commons Attribution 4.0 International licence (CC BY 4.0); see
`inst/extdata/LICENSE-DATA.md`. Short verbatim quotes in the registers remain
the work of the authors of the studies listed in `screening.csv`. No full
text of any study is distributed. A data dictionary is in
`inst/extdata/README.md`.

## Citation

Montaletti, G. (2026). interfacespace: Registers of joint
qualitative-quantitative claims (Version 0.1.0) [R package].
Zenodo. https://doi.org/10.5281/zenodo.24306874

All versions (concept DOI): https://doi.org/10.5281/zenodo.24306873

```bibtex
@Manual{montaletti2026interfacespace,
  title  = {interfacespace: Registers of joint qualitative-quantitative claims},
  author = {Giampaolo Montaletti},
  year   = {2026},
  note   = {R package version 0.1.0},
  url    = {https://github.com/gmontaletti/interfacespace},
  doi    = {10.5281/zenodo.24306874},
}
```
