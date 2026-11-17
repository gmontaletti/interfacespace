# Recode protocol: ten evaluations as interface spaces (task T1)

Version 0.3, 17 November 2026. Status: approved by the author; coding rules 1-4 added after study HLT-C2, rules 5-6 after PA-2.4, rules 7-8 after HLT-C12, rules 9-11 after HLT-C15, rules 12-13 after HLT-C5 (17 November 2026).
Paper: IRSPM 2027 (see ../../paper_irspm2027/02_chapter_plan.md, section 4).

## 1. Purpose
Build, for each of ten evaluations not coded before, the register of the interface space (findings, transformations, claims, relations, decisions) and count two things per study:
- joint claims: headline claims whose findings, traced back to their roots, include at least one qualitative and one quantitative finding;
- relations among claims: backs, clashes, covers.

The recode is itself run as an interface space: an LLM proposes every row as a candidate; the author endorses or rejects each candidate with a written reason.

## 2. Studies
- Source: the 16 "likely" candidates not coded before, from ../ricerca_ampliata/06_candidati_consolidati.csv, taken in rank order.
- Excluded before screening: MD-C5, MHCLG (2025) Changing Futures final report (same programme as study 26 of the 44-study corpus).
- Order (rank): HLT-C2 Woodall 2018; HLT-C12 Sweeney 2014; HLT-C9 McCullough 2020; MD-C8 Johnsen 2022; PA-2.4 Gazley 2008; HLT-C15 Gulliford 2006; HLT-C5 Raine 2014; MD-C11 MHCLG/ICF 2024; SOC-C13 Forrester 2017; SOC-C15 McCracken 2017; SOC-C4 Baginsky 2020; SOC-C7 Kaye 2024; SOC-C8 Lietz 2009; HLT-C14 Burns 2007; SOC-C16 Mason 2017.
- Paywalled texts (McCullough, Gazley, Lietz; Baginsky and Kaye if not open) are supplied by the author and keep their place in the order.
- Stop when ten studies pass full-text eligibility. If the list runs out, continue with the 35 "borderline" candidates in their listed order.
- Eligibility on full text: the object is a relationship in a public or publicly funded service; the study reports at least one qualitative and one quantitative finding. (Author decision, 17 November 2026: the old requirement of at least one joint claim is dropped, so joint claims are an outcome.)
- Every eligibility decision is recorded in screening.csv with a reason.

## 3. Scope within a study
Headline claims only: claims in the abstract or executive summary, and in the conclusions or recommendations. Findings are registered only when a headline claim rests on them, or when they are the study's main reported results.

## 4. Tables (one folder per study: registers/<ID>/)
Codes are never reused or renumbered. Rows are never deleted; corrections are new rows.

- agents.csv: code, name, type (person / model / algorithm), description.
  - A1 = author of the decisions (person). A2 = LLM extractor (model, with model id and prompt version). S1 = the study's authors (person, as the source of the claims).
- findings.csv: code (F1...), strand (Q / N), where_to_check (page, table, section), finding (one sentence), quote (short, verbatim), proposed_by, status.
- transformations.csv: new_finding, made_from, method (plain words), done_by (S1 when the study did it), crosses_strand (yes / no).
- claims.csv: code (C1...), claim (as stated, shortened only when needed), location (abstract / executive summary / conclusions / recommendations, with page), rests_on (finding codes), fit (confirm / expand / discord / single-strand), origin (data, as stated by S1), proposed_by (A2 for the extraction), status.
- relations.csv: code (R1...), from, relation (backs / clashes / covers), to, basis (quote or page showing the link), proposed_by, status.
- decisions.csv: code (D1...), date, who (A1), action (endorse / reject), rows (codes), reason (written out).

Status of every proposed row starts as candidate. Only a row in decisions.csv changes it.

## 5. Extraction (LLM, role A2)
- Extract only: the LLM proposes findings, the study's headline claims, what each claim rests on, transformations reported by the study, and relations among claims. It does not propose new claims.
- Every row carries a page reference and a short verbatim quote.
- A relation is proposed only when the text states the link or shows it directly in the argument (the basis column says which).
- rests_on lists the findings the text itself uses for the claim; when the text gives no finding, rests_on is empty and the claim is recorded as unsupported in the text.

### Coding rules (author decisions, 17 November 2026)
- Rule 1, splitting: a sentence that asserts separable things is split, one claim per assertion (e.g. one claim per outcome).
- Rule 2, summary claims: a claim that summarises other claims without citing findings at that point has an empty rests_on; its link to the claims it summarises is recorded as a 'covers' relation.
- Rule 3, rests_on: only the findings the text itself uses for the claim. Findings elsewhere in the study that bear on the claim but are not linked by the authors are noted in 00_extraction_notes.md, not in rests_on.
- Rule 4, clashes: a relation is 'clashes' only when both claims cannot hold together. A qualification that both claims survive is not a clash (no relation, or 'covers' if one narrows the other).
- Rule 5, examples: a list of examples inside one assertion is not split; rule 1 applies to separable assertions only.
- Rule 6, research agenda: recommendations for future research are not headline claims and are rejected. Recommendations for practice or policy remain headline claims.
- Rule 7, argued elsewhere: when the same claim is argued with findings elsewhere in the text (e.g. Discussion), it rests on those findings; the passage is quoted in the extraction notes.
- Rule 8, restated results: a claim that restates a reported result on the same measure or theme rests on that finding even without an explicit pointer; thematic similarity alone is not enough (rests_on stays empty).
- Rule 9, instruments: when qualitative work shapes an instrument (e.g. questionnaire items written from interview themes), this is a design-level interface point recorded in the notes, not a transformation of findings; the instrument's findings stay N roots.
- Rule 10, implied links: 'backs' is recorded only when the text marks the link (therefore, so, this suggests, an explicit pointer); sequence in the argument alone is not a relation.
- Rule 11, repeated claims: the same claim in several places (executive summary, findings summary, conclusions) is one row listing every location. 'Same claim' means the same assertion, whatever the wording ('we found X' and 'we conclude X' are one claim); a claim that summarises several different claims is not a repeat and follows rule 2. (Boundary set by the author, 17 November 2026; earlier registers are re-checked in the consistency pass.)
- Rule 12, case groups: a finding that compares qualitative data across groups defined by a quantitative measure (e.g. themes in high- vs lower-implementing teams) is a strand-crossing transformation; the resulting finding roots in both strands.
- Rule 13, new data from earlier results: when earlier results are turned into instrument content (e.g. statements rated by a panel), the new responses are new data (N or Q by form), as in rule 9; the step is a design-level interface point recorded in the notes.
- Rule 14, quantitizing the same data (author decision 2026-11-17T15:06:36Z, during the fresh recode, after 7 fresh extractions and before any fresh decision; it states the existing practice of workbook Check 1 and of SOC-C13 F6/F16): counts, ratings or proportions produced by coding the same qualitative material (e.g. network counts coded from interview transcripts) pass on only the qualitative root; they are not new N roots. Rules 9 and 13 (new data from new respondents or instruments) do not apply to them.

## 6. Decisions (author, role A1)
- The author reviews each candidate row and records endorse or reject with a reason.
- Reasons for rejection include: not a headline claim; not a finding; wrong strand; rests_on incomplete or wrong; relation not supported by the text.
- Corrections are proposed as new rows and decided like any other row.

## 7. Counts (from endorsed rows only)
Per study:
- headline claims (endorsed);
- joint claims: claims whose rests_on, traced back through transformations to root findings, includes at least one Q and one N root (a rule-12 transformation output counts as a root of its own strand together with the roots it was made from; other transformations pass on only the roots they were made from). Computed by compute_counts.py;
- claims in at least one endorsed relation, and their share of headline claims;
- clashes (endorsed relations of type clashes);
- LLM candidates proposed, endorsed, rejected (by table), with the main reasons for rejection.
Pooled: the same counts across the ten studies. Comparison with the author's recorded predictions (1-2 joint claims per study; about 50% of claims related; some clashes stated openly).

## 8. Open points for the author
- Resolved: joint-claim requirement dropped from eligibility (see section 2).
- Texts to supply by the author: HLT-C9 McCullough 2020, PA-2.4 Gazley 2008, SOC-C8 Lietz 2009, HLT-C5 Raine 2014 (PDF download blocked; HTML at https://www.ncbi.nlm.nih.gov/books/NBK260189/).
- Notes on texts: SOC-C4 Baginsky is the accepted author manuscript; HLT-C15 Gulliford is the full 183-page report (executive summary kept separately).
- One study's register is shown in full in the paper; which one is chosen after the recode.
