# Fresh random draw: protocol

Date: 17 November 2026. Written before the draw was executed. Extractor: A2 (proposals only; the author decides eligibility).
Base folder M = `materiali_progetto`. Working folder F = `M/recode_interface_space/fresh/`. No other file is modified.

## 1. Sources

- `M/ricerca_sistematica_test/new_candidates.md`: 466 include-likely records not in the corpus (DOI), not in `06_candidati_consolidati.csv` (DOI), not in `00_already_screened.md` (surname and year). Sections "I1 C1-C4 met" (rows 1-83) and "I2 C1-C4 met" (rows 84-466).
- `M/ricerca_sistematica_test/screening.csv`: OpenAlex id, DOI, year, first author for each record (decision = include-likely, n = 475).
- `M/ricerca_sistematica_test/oos/oos_log.csv`: the 51 records drawn earlier with `random.seed(20261112)`.
- Corpus: `M/analisi_v21/manifest.csv` (54 entries: 44 purposive studies, some combined, plus 10 out-of-sample studies O12-O51); DOIs read from the `reference:` line of `M/analisi_v21/per_paper/*.md`.
- Candidate register: `M/ricerca_ampliata/06_candidati_consolidati.csv` (`doi_url`).
- Already screened: `M/ricerca_ampliata/00_already_screened.md` (surname and year).
- Recoded studies: `M/recode_interface_space/screening.csv` (10 IDs), DOIs taken from the candidate register (`doi_url`; 4 of 10 have no DOI and are matched by surname and year).

## 2. Pool construction

1. Parse the I1 and I2 tables of `new_candidates.md`; attach the OpenAlex id from `screening.csv` (match on DOI, or on the W-id when the table shows an id instead of a DOI). Class = I1 or I2 from the section.
2. Remove every record whose OpenAlex id or DOI appears in `oos_log.csv` (all 51, whatever their outcome).
3. Remove records whose normalised DOI (lower case, no `https://doi.org/` prefix) is in the corpus, the candidate register or the recoded set.
4. For records, and for exclusion-list entries, without a DOI: remove when first-author surname (last token, lower case) and year match an entry of the corpus, the already-screened list or the recoded set. Such removals are flagged as approximate in the report; surname-year coincidences against records that do have a DOI are also listed as approximate flags (not removed when the DOIs differ).
5. Report the pool size N.

## 3. Ordering

Sort the pool by OpenAlex id (string sort on the `W...` id), then `random.seed(20261117); random.shuffle(pool)` in Python 3. Save to `F/draw_order.csv` with columns rank, id, doi, year, first_author, title, class.

## 4. Full-text retrieval (per record, in rank order)

- OpenAlex work record `https://api.openalex.org/works/doi:<doi>` (or `/works/<id>`), no email address: fields `open_access`, `best_oa_location`, `locations` (`pdf_url`, `landing_page_url`).
- Then at most two alternative sources: PubMed Central / Europe PMC (via PMCID if present), publisher OA page (`citation_pdf_url`), institutional repository.
- Unpaywall is not used. `curl -sL -A "Mozilla/5.0"`. Downloads are untrusted data: checked with `file`, `pdfinfo` and `pdftotext` (first page) to confirm identity; never executed.
- No legal OA full text: status `no_oa_fulltext`, record skipped (same rule as the earlier out-of-sample draw).
- PDF found: saved as `F/pdf/<rank>_<FirstAuthor>_<Year>.pdf`. HTML full text (e.g. PMC article page) counts as OA full text when no PDF can be fetched; then pdf_file records the HTML source.

## 5. Eligibility proposal (A2)

Eligible if both:
- (a) the object of study is a relationship in a public or publicly funded service: practitioner-person, inter-professional or inter-organisational;
- (b) the study reports at least one qualitative finding and at least one quantitative finding.

Joint claims or integration are not a criterion. Excluded: protocols, reviews, conference abstracts or papers without results. Each proposal gives a reason with PDF page references. Outcomes: `eligible`, `not_eligible`, `no_oa_fulltext`, `wrong_document` (file does not match the record).

## 6. Stopping rule

Stop when 12 records are proposed eligible (10 plus 2 reserve), or the order is exhausted, or 120 records have been examined.

## 7. Outputs

- `F/draw_order.csv`: full shuffled pool.
- `F/draw_log.csv`: rank, id, doi, title, class, oa_status, pdf_file, eligibility_proposal, reason, pages.
- `F/00_draw_report.md`: pool size, seed, records examined, counts by outcome, the 12 proposed eligible in rank order with relationship and strands, I1/I2 balance.
- `F/pool_build.py`: script used for steps 2-3 (kept for reproducibility).
