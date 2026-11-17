# Data dictionary

This folder holds the material of the recode of ten published mixed methods
evaluations of public services (data licence: CC BY 4.0, see
`LICENSE-DATA.md`).

| Path | Content |
|---|---|
| `00_protocol.md` | Final coding protocol: tables, extraction, coding rules 1-13, decisions, counts. |
| `01_extraction_prompt_v1.md`, `_v2.md`, `_v3.md` | Prompts given to the language model that proposed candidate rows (role A2). |
| `02_decision_proposal_prompt.md` | Prompt for the model that proposed decisions and correction rows (role A3). |
| `03_consistency_prompt.md` | Prompt for the consistency pass across registers. |
| `screening.csv` | Eligibility decisions on the candidate studies. |
| `registers/<ID>/` | One register per study: six CSV tables and the notes `00_*.md`. |

All files are UTF-8, comma-separated, with a header row and quoted
values. Codes are never reused or renumbered and rows are never deleted;
corrections are new rows. Lists of codes are separated by `;`.

## screening.csv

| Column | Description |
|---|---|
| `ID` | Study identifier (e.g. `HLT-C2`); also the name of the register folder. |
| `reference` | Short reference (authors, year). |
| `file` | File name of the full text used for the recode (not distributed). |
| `decision` | Eligibility decision (`eligible` or not). |
| `reason` | Reason for the decision, written out. |
| `date` | Date of the decision (ISO 8601). |
| `decided_by` | Agent code of the decision-maker (`A1`). |

## registers/&lt;ID&gt;/agents.csv

| Column | Description |
|---|---|
| `code` | Agent code. `A1` author of the decisions; `A2` model that extracted candidate rows; `A3` model that proposed decisions and correction rows; `S1` the study's authors (source of the claims and of transformations done in the study). |
| `name` | Person name, author list or model identifier. |
| `type` | `person`, `model` or `algorithm`. |
| `description` | Role, model version and prompt version. |

## registers/&lt;ID&gt;/findings.csv

| Column | Description |
|---|---|
| `code` | Finding code (`F1`, `F2`, ...). |
| `strand` | `Q` (qualitative: interviews, observation, open answers) or `N` (quantitative: scales, counts, estimates). The strand of the form the finding has. |
| `where_to_check` | Page, table or section where the finding can be checked. |
| `finding` | The finding, in one sentence. |
| `quote` | Short verbatim quote from the study. |
| `proposed_by` | Agent code of the proposer. |
| `status` | `candidate`, `endorsed` or `rejected`, as set by the latest decision on the row. |

## registers/&lt;ID&gt;/transformations.csv

A transformation produces a finding from other findings (e.g. counting a
theme, comparing themes across groups defined by a measure). It is decided
with the row key `T:<new_finding>`.

| Column | Description |
|---|---|
| `new_finding` | Code of the output finding (a free-text label for two rejected rows of HLT-C15 that are not registered findings). |
| `made_from` | Codes of the input findings. |
| `method` | The method, in plain words, with page reference. |
| `done_by` | Agent code of who did it (`S1` when the study did it). |
| `crosses_strand` | `yes` when input and output belong to different strands, otherwise `no`. |
| `proposed_by` | Agent code of the proposer. |
| `status` | As in `findings.csv`. |

Coding rule 12 (qualitative data compared across groups defined by a
quantitative measure) is not a column: it is recorded in `decisions.csv` by
an `endorse` decision whose reason mentions "Rule 12". `read_register()`
stores it as `partition = TRUE`; the output finding then counts as a root of
its own strand in addition to the roots of `made_from`.

## registers/&lt;ID&gt;/claims.csv

| Column | Description |
|---|---|
| `code` | Claim code (`C1`, ...). |
| `claim` | The headline claim as stated, shortened only when needed (`[...]`). |
| `location` | Where it is stated (abstract, executive summary, conclusions, recommendations), with page; every location for a repeated claim (rule 11). |
| `rests_on` | Codes of the findings the text itself uses for the claim; empty when the text gives none. |
| `fit` | How the strands relate inside the claim: `confirm`, `expand`, `discord`, `single-strand`; empty when not recorded. |
| `origin` | Origin of the claim as stated by the study (free text, e.g. `data: ...`). |
| `proposed_by` | Agent code of the proposer. |
| `status` | As in `findings.csv`. |

## registers/&lt;ID&gt;/relations.csv

| Column | Description |
|---|---|
| `code` | Relation code (`R1`, ...). |
| `from` | Code of the first claim. |
| `relation` | `backs` (gives reasons for), `clashes` (both cannot hold), `covers` (is the broader claim that includes). |
| `to` | Code of the second claim. |
| `basis` | Quote or page showing the link in the text. |
| `proposed_by` | Agent code of the proposer. |
| `status` | As in `findings.csv`. |

## registers/&lt;ID&gt;/decisions.csv

| Column | Description |
|---|---|
| `code` | Decision code (`D1`, ...), in the order taken. |
| `date` | Date (ISO 8601). |
| `who` | Agent code of the decision-maker (a person; `actor` in the package). |
| `action` | `endorse` or `reject`. |
| `rows` | Codes of the rows decided: `F`, `C`, `R` codes, `T:<new_finding>` for transformations, or `eligibility` for the study-level eligibility decision. |
| `reason` | The reason, written out, citing coding rules where relevant. |

A later decision on the same row supersedes an earlier one. The `status`
columns of the other tables equal the result of replaying the decisions in
order.

## registers/&lt;ID&gt;/00_*.md

Working notes kept with each register: `00_eligibility_proposal.md`
(proposed eligibility), `00_extraction_notes.md` (extraction notes,
including findings that bear on a claim but are not linked by the authors,
and design-level interface points under rules 9 and 13),
`00_decision_proposal.md` and `00_consistency_proposal.md` (proposals of
the model A3 reviewed by the author).
