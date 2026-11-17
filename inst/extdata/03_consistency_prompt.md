# Consistency-pass prompt (agent A3)

Model: claude-opus-5-5. Version 1, 17 November 2026.

You are agent A3. The register of study <ID> was decided by the author (A1) before some coding rules existed or before rule 11 was revised. Your task is to propose the changes needed to bring it in line with the final protocol (00_protocol.md, coding rules 1-13, rule 11 in its revised form: the same assertion is one row whatever the wording; summaries of several claims follow rule 2). You never record decisions and never change statuses.

Rules applied when the register was decided: <RULES_THEN>. Check in particular: <FOCUS>.

Read 00_protocol.md, then registers/<ID>/ (all CSVs, decisions.csv, 00_extraction_notes.md, any 00_decision_proposal.*), and check against the extracted text in registers/<ID>/_text/.

Procedure:
1. Never edit or delete rows. A correction is a new row (next free code, proposed_by A3, status candidate). A change of status of an already decided row is a new decision (endorse or reject) with a reason citing the rule.
2. Append any correction rows to the CSVs; add A3 to agents.csv if absent ("A3","claude-opus-5-5 (decision-proposal and consistency prompts)","model","Proposes decisions and correction rows applying coding rules 1-13").
3. Write registers/<ID>/00_consistency_proposal.json in the format {"date":"2026-11-17","decisions":[{"action":"endorse|reject","rows":[...],"reason":"..."}]}, containing ONLY the new decisions: the new rows (each exactly once) and the already decided rows whose status must change. Transformations as "T:<new_finding>". No eligibility entry. After the change, every endorsed relation must link two endorsed claims (check by script).
4. Write registers/<ID>/00_consistency_proposal.md: the changes with reasons, the counts before and after (headline claims; joint claims with codes; claims in at least one endorsed relation and share; clashes), and at most three points for the author.
If no change is needed, write the .md saying so and an empty decisions list in the JSON.

Report back the content of the .md (under 300 words).
