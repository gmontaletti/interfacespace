# 1. a small synthetic space -----

make_space <- function() {
  x <- InterfaceSpace$new("synthetic")
  x$add_agent("A1", "Analyst", "person", "Author of the decisions")
  x$add_agent("A2", "LLM extractor", "model", "model x, prompt v1")
  x$add_agent("S1", "Study authors", "person")
  x$add_finding("F1", "Q", "Participants report growing confidence.",
                where_to_check = "Interviews, p. 7", proposed_by = "A2")
  x$add_finding("F2", "N", "Confidence theme present in 68% of interviews.",
                where_to_check = "Table 3", proposed_by = "A2")
  x$add_finding("F3", "N", "Implementation rate differs across teams.",
                where_to_check = "Table 4", proposed_by = "A2")
  x$add_finding("F4", "Q", "Themes differ between high- and low-implementing
                teams.", where_to_check = "p. 20", proposed_by = "A2")
  x$add_finding("F5", "Q", "Staff describe meetings as rushed.",
                where_to_check = "p. 22", proposed_by = "A2")
  x
}

# 2. jointness -----

test_that("a theme plus its own quantitized percentage is not joint", {
  x <- make_space()
  x$add_transformation("F2", made_from = "F1", method = "theme counted",
                       done_by = "S1", proposed_by = "A2")
  x$propose_claim("C1", "Coaching raises confidence.",
                  rests_on = c("F1", "F2"), fit = "confirm",
                  proposed_by = "A2")
  x$decide(c("F1", "F2", "T:F2", "C1"), "endorse", actor = "A1",
           reason = "Recorded as stated.")
  expect_true(x$transformations()$crosses_strand)
  expect_false(x$is_joint("C1"))
  expect_identical(x$roots("C1")$root, "F1")
  expect_equal(x$counts()$joint, 0L)
})

test_that("a rule-12 partition transformation is joint", {
  x <- make_space()
  x$add_transformation("F4", made_from = c("F3", "F5"), partition = TRUE,
                       method = "themes compared across teams grouped by F3",
                       done_by = "S1", proposed_by = "A2")
  x$propose_claim("C1", "High-implementing teams plan differently.",
                  rests_on = "F4", fit = "expand", proposed_by = "A2")
  x$decide(c("F3", "F4", "F5", "T:F4", "C1"), "endorse", actor = "A1",
           reason = "Rule 12 transformation, recorded as stated.")
  expect_true(x$is_joint("C1"))
  expect_setequal(x$roots("C1")$root, c("F3", "F4", "F5"))
  # without the partition flag the output passes on only its inputs' roots
  y <- make_space()
  y$add_transformation("F4", made_from = "F5", proposed_by = "A2")
  y$propose_claim("C1", "Claim.", rests_on = "F4", proposed_by = "A2")
  y$decide(c("F4", "F5", "T:F4", "C1"), "endorse", actor = "A1",
           reason = "Recorded.")
  expect_false(y$is_joint("C1"))
})

test_that("jointness uses endorsed rows only and does not gate endorsement", {
  x <- make_space()
  x$propose_claim("C1", "Mixed claim.", rests_on = c("F1", "F3"),
                  fit = "confirm", proposed_by = "A2")
  x$decide("C1", "endorse", actor = "A1", reason = "Recorded as stated.")
  # endorsed although its findings are still candidates: not joint yet
  expect_identical(x$claims()$status, "endorsed")
  expect_false(x$is_joint("C1"))
  x$decide(c("F1", "F3"), "endorse", actor = "A1", reason = "Findings ok.")
  expect_true(x$is_joint("C1"))
  # a single-strand claim can be endorsed too
  x$propose_claim("C2", "Single-strand claim.", rests_on = "F3",
                  fit = "single-strand", proposed_by = "A2")
  x$decide("C2", "endorse", actor = "A1", reason = "Recorded as stated.")
  expect_identical(x$claims("endorsed")$code, c("C1", "C2"))
})

# 3. decisions -----

test_that("decisions need a reason and a person as actor", {
  x <- make_space()
  expect_error(x$decide("F1", "endorse", actor = "A1", reason = ""),
               "reason")
  expect_error(x$decide("F1", "endorse", actor = "A1", reason = NA),
               "reason")
  expect_error(x$decide("F1", "endorse", actor = "A2", reason = "ok"),
               "person")
  expect_error(x$decide("F99", "endorse", actor = "A1", reason = "ok"),
               "unknown row")
  expect_equal(nrow(x$decisions()), 0L)
  expect_identical(unique(x$findings()$status), "candidate")
})

test_that("machine-proposed rows cannot be endorsed at creation", {
  x <- make_space()
  expect_error(
    x$propose_claim("C1", "Machine claim.", rests_on = "F1",
                    proposed_by = "A2", endorse = "looks right"),
    "cannot be endorsed in the call that creates them"
  )
  expect_false("C1" %in% x$claims()$code)
  x$propose_claim("C1", "Machine claim.", rests_on = "F1", proposed_by = "A2")
  expect_identical(x$claims()$status, "candidate")
  # a person may endorse in the creating call; this records a decision
  x$propose_claim("C2", "Analyst claim.", rests_on = "F1", proposed_by = "A1",
                  endorse = "Analyst's own reading of F1.")
  expect_identical(x$claims()[code == "C2", status], "endorsed")
  expect_equal(nrow(x$decisions()), 1L)
})

test_that("decisions are append-only and the latest wins", {
  x <- make_space()
  x$decide("F1", "endorse", actor = "A1", reason = "First reading.")
  x$decide("F1", "reject", actor = "A1", reason = "Wrong strand.")
  expect_identical(x$findings()[code == "F1", status], "rejected")
  x$decide("F1", "endorse", actor = "A1", reason = "Strand confirmed.")
  expect_identical(x$findings()[code == "F1", status], "endorsed")
  expect_identical(x$decisions()$code, c("D1", "D2", "D3"))
  expect_error(x$decide("F2", "endorse", actor = "A1", reason = "x",
                        code = "D1"), "already used")
  expect_false(any(c("delete", "edit", "remove") %in% names(x)))
})

test_that("codes are never reused", {
  x <- make_space()
  expect_error(x$add_finding("F1", "Q", "Again.", proposed_by = "A2"),
               "never reused")
  x$add_finding(NULL, "Q", "Next.", proposed_by = "A2")
  expect_true("F6" %in% x$findings()$code)
  expect_error(x$add_agent("A1", "Other", "person"), "already registered")
})

# 4. validate -----

test_that("validate reports violations", {
  x <- make_space()
  x$propose_claim("C1", "Claim one.", rests_on = c("F1", "F3"),
                  proposed_by = "A2")
  x$propose_claim("C2", "Claim two.", rests_on = "F3", proposed_by = "A2")
  x$relate("C1", "covers", "C2", proposed_by = "A2")
  x$decide(c("F1", "F3", "C1", "R1"), "endorse", actor = "A1",
           reason = "Recorded.")
  v <- x$validate()
  expect_setequal(v$check, c("relation_nonendorsed_claim",
                             "joint_claim_single_strand_fit"))
  expect_identical(v[check == "relation_nonendorsed_claim", row], "R1")

  # lenient mode keeps invalid decisions and reports them
  y <- InterfaceSpace$new("lenient", strict = FALSE)
  y$add_agent("A1", "Analyst", "person")
  y$add_agent("A2", "Model", "model")
  y$add_finding("F1", "Q", "A finding.", proposed_by = "A2")
  expect_warning(y$decide("F1", "endorse", actor = "A2", reason = ""))
  v <- y$validate()
  expect_setequal(v$check, c("decision_without_reason",
                             "decision_not_by_person"))
})

test_that("input validation gives informative errors", {
  x <- make_space()
  expect_error(x$add_finding("F9", "X", "Bad strand.", proposed_by = "A2"))
  expect_error(x$propose_claim("C1", "Claim.", rests_on = "F99",
                               proposed_by = "A2"), "Unknown finding")
  expect_error(x$propose_claim("C1", "Claim.", fit = "agree",
                               proposed_by = "A2"), "fit")
  expect_error(x$relate("C1", "backs", "C2", proposed_by = "A2"),
               "Unknown claim")
  expect_error(x$add_finding("F9", "Q", "No agent.", proposed_by = "Z9"),
               "registered agent")
  expect_error(InterfaceSpace$new(""), "study")
})

test_that("empty spaces return empty tables and counts", {
  x <- InterfaceSpace$new("empty")
  expect_equal(nrow(x$claims()), 0L)
  expect_equal(nrow(x$roots()), 0L)
  expect_length(x$is_joint(), 0L)
  expect_equal(x$counts()$claims, 0L)
  expect_equal(nrow(x$validate()), 0L)
  expect_equal(nrow(x$joint_display()), 0L)
  expect_output(print(x), "InterfaceSpace")
})
