# HLT-C15 extraction notes (A2)

Text: pdftotext -layout of the supplied PDF, saved in _text/full.txt; _text/paged.txt and _text/compact.txt carry page tags. Page numbers are the report's printed page numbers (they coincide with PDF page numbers). Quotes are verbatim; some span a line break, a page break or a hyphenated word ("continuity-of-care"), so a plain string search may miss them. "[...]" marks omissions.

## Rows proposed
- findings: 51 (Q 26, N 25). transformations: 2. claims: 88. relations: 40 (covers 26, backs 14, clashes 0). decisions: header only.
- Headline scope: executive summary "What we found" and "What we conclude" paragraphs (p.7-11), Section 11 Conclusions (p.140-142), Section 12 Recommendations (p.143). "What we did" paragraphs are treated as methods, not claims.

## Look at first
1. Duplicated wording across headline sections. The executive summary repeats the section summaries; Section 11 repeats much of the executive summary; recommendations p.11 and p.143 are identical. Where the meaning is the same, one claim row carries both locations (e.g. C16, C18, C19, C23, C24, C28-C34, C41, C46, C48-C50, C52, C75-C88). Where Section 11 words a point differently and adds a separable assertion, a new row was made (C53-C74). A1 may prefer one row per location; that would raise the claim count by about 15.
2. Transformations (instrument built from qualitative themes). The study states it "used the qualitative data to develop a 19-item measure" (p.8, p.56-60, Table 9) and did the same for the professional questionnaire (p.124). Two rows are proposed with new_finding = the instrument, not a finding code. The survey scores are new quantitative data collected with an instrument whose items come from interviews; they are not computed from the interview findings. In the counts below this link is NOT propagated. If A1 decides that instrument-based findings have Q roots via these rows, every claim resting on ECC-DM or professional-questionnaire findings (C8-C27, C30-C32, C47, C48, etc.) becomes joint; that would make most headline claims joint and probably over-counts.
3. Joint claims (rests_on with both strands, no propagation via instruments): C55 (hospital settings: patient interviews F7 + patient survey F17 + professional survey F50; confirm), C56 (language: F36 + F21; confirm), C57 (professional view that continuity leads to better care F40 vs null outcomes F28-F30; discord, stated by S1 as "an area of discrepancy"), C50 (professionals' greater awareness of seamless-service issues: F43 interviews + F51 questionnaire comparison p.137-138; confirm). C50 is borderline: the executive summary cites no finding; the link to F51 comes from Section 10.8, where S1 argue that professionals "give greater emphasis to the notion of a ‘seamless service’".
4. Rule 3 cases where the text links the other strand outside the headline sentence:
   - C19 (hospital clinics lower ECC) rests on F17 only. Section 7 adds "These results are consistent with qualitative data" (p.79) and "This is consistent with the qualitative data" (p.84), i.e. F7. Adding F7 makes C19 joint (confirm). The joint version of this point is C55.
   - C39 (language, executive summary) rests on F36 only; p.113 links it to Table 22 (F21). Adding F21 makes C39 joint and duplicates C56.
   - C60, C61 (patients judge the caring relationship, professionals the seamless service) have empty rests_on; Section 10.8 (p.138) uses F51 and Section 6.4.4 (p.52) F10 for a similar argument; F22 (team/cross-boundary scores do not vary) is used at p.84-85 with the remark that patients "are not well able to judge these aspects".
   - C41 (vulnerable groups) has empty rests_on (Rule 2); "disability" corresponds to the housebound finding F34, which no executive-summary sentence reports.
5. Restatement conclusions (C18, C19, C23, C24, C30-C32, C63) were given the findings their section links to them, not empty rests_on, because each restates a single result rather than summarising several claims. If A1 applies Rule 2 to them, rests_on becomes empty and 'covers' relations to C15, C14, C22, C25-C27, C7 would be needed.
6. Backs relations from conclusions to recommendations (R35-R37) are "shown in argument" only: the recommendations restate conclusions without saying "because". R38-R40 have closer textual repetition. Candidates for rejection under the HLT-C2 precedent (R8 rejected).
7. No clash proposed. The only stated contrast (C57) is internal to one claim, between a finding (F40) and results (F28-F30), not between two headline claims. C49 vs C50 ("However") is a qualification both survive (Rule 4).
8. C8, C9, C20, C21 are descriptive statistics in "What we found"; kept as claims because they are stated in the executive summary. A1 may reject them as non-claims.
9. C46 merges the executive summary sentence on the measure's dimensions with 11.9 "Five dimensions were identified"; rests on F46 (interviews). The factor-analysis support (F48) is not cited for it.

## Other
- C33 and C34 rest on hypothetical scenarios (Table 32, p.99) and literature, not on data of this study.
- C51, C72, C74 rest on literature (Ouwens et al. 2005; general quality-of-care literature).
- Response rate 38% at baseline (F23) and 43%/55% in the professional survey (p.125) are limitations stated by S1 (p.85, p.100).
- Findings registered as main results but not in any rests_on: F10, F19, F22, F34, F41, F42.
