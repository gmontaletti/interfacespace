# 1. decision origin of the bundled registers -----

org <- decision_origin_summary(bundled_registers())
org_all <- org[table == "all"]

test_that("origin counts per study are as derived from the proposal files", {
  exp <- data.table::data.table(
    study = c(
      "HLT-C2",
      "HLT-C12",
      "HLT-C9",
      "MD-C8",
      "PA-2.4",
      "HLT-C15",
      "HLT-C5",
      "MD-C11",
      "SOC-C13",
      "SOC-C15"
    ),
    decisions = c(16L, 16L, 17L, 23L, 11L, 38L, 39L, 27L, 18L, 18L),
    unchanged = c(9L, 6L, 16L, 23L, 5L, 38L, 39L, 18L, 18L, 18L),
    modified = c(0L, 4L, 1L, 0L, 0L, 0L, 0L, 9L, 0L, 0L),
    other = c(7L, 6L, 0L, 0L, 6L, 0L, 0L, 0L, 0L, 0L),
    reversed_later = c(0L, 0L, 0L, 0L, 0L, 0L, 3L, 0L, 0L, 0L)
  )
  expect_identical(org_all$study, exp$study)
  for (v in setdiff(names(exp), "study")) {
    expect_identical(org_all[[v]], exp[[v]], label = v)
  }
  expect_true(all(org$no_origin == 0L))
  pooled <- decision_origin_summary(bundled_registers(), pooled = TRUE)[
    study == "pooled" & table == "all"
  ]
  expect_equal(pooled$decisions, 223L)
  expect_equal(pooled$unchanged, 190L)
  expect_equal(pooled$modified, 14L)
  expect_equal(pooled$other, 19L)
})

test_that("decisions() exposes proposed_by and accepted", {
  x <- read_register(bundled_registers("HLT-C9"))
  d <- x$decisions()
  expect_true(all(c("proposed_by", "accepted") %in% names(d)))
  expect_identical(d[code == "D17", proposed_by], "A1")
  expect_identical(d[code == "D17", accepted], "modified_by_author")
  expect_identical(unique(d[code != "D17", proposed_by]), "A3")
  expect_match(x$decision_origin()[decision == "D17", note], "endorse R7")
})

test_that("main-session proposals use agent A4, registered as a model", {
  for (id in c("HLT-C2", "HLT-C12", "PA-2.4")) {
    x <- read_register(bundled_registers(id))
    expect_identical(x$agents()[code == "A4", type], "model")
    d <- x$decisions()
    expect_true(all(d[proposed_by == "A4", accepted] == "unchanged"))
  }
})

test_that("decision_origin.csv agrees with the proposal files", {
  skip_if_not_installed("jsonlite")
  key <- function(it) {
    paste(it$action, paste(it$rows, collapse = ";"), it$reason, sep = "\r")
  }
  for (p in bundled_registers()) {
    jf <- list.files(p, pattern = "^00_.*\\.json$")
    keys <- lapply(stats::setNames(jf, jf), function(f) {
      js <- jsonlite::fromJSON(file.path(p, f), simplifyVector = FALSE)
      vapply(js$decisions, key, character(1))
    })
    dec <- data.table::fread(
      file.path(p, "decisions.csv"),
      colClasses = "character"
    )
    og <- data.table::fread(
      file.path(p, "decision_origin.csv"),
      colClasses = "character",
      na.strings = NULL
    )
    expect_identical(og$decision, dec$code, label = basename(p))
    k <- paste(dec$action, dec$rows, dec$reason, sep = "\r")
    in_file <- function(f, kk) f %in% names(keys) && kk %in% keys[[f]]
    for (i in seq_len(nrow(dec))) {
      lab <- paste(basename(p), dec$code[i])
      if (og$proposed_by[i] == "A3") {
        expect_match(og$source_file[i], "_proposal\\.json$", label = lab)
        expect_true(in_file(og$source_file[i], k[i]), label = lab)
      } else if (og$proposed_by[i] == "A1") {
        expect_match(og$source_file[i], "_final\\.json$", label = lab)
        expect_true(in_file(og$source_file[i], k[i]), label = lab)
        prop <- sub("_final", "_proposal", og$source_file[i])
        expect_false(in_file(prop, k[i]), label = lab)
      } else {
        expect_identical(og$proposed_by[i], "A4", label = lab)
        expect_false(
          any(vapply(keys, function(v) k[i] %in% v, logical(1))),
          label = lab
        )
      }
    }
  }
})

# 2. origin on a synthetic space -----

make_origin_space <- function() {
  x <- InterfaceSpace$new("synthetic")
  x$add_agent("A1", "Analyst", "person")
  x$add_agent("A2", "Extractor", "model")
  x$add_agent("A3", "Proposer", "model")
  x$add_finding("F1", "Q", "Finding one.", proposed_by = "A2")
  x$add_finding("F2", "N", "Finding two.", proposed_by = "A2")
  x$propose_claim(
    "C1",
    "Claim one.",
    rests_on = c("F1", "F2"),
    proposed_by = "A2"
  )
  x$decide(c("F1", "F2"), "endorse", actor = "A1", reason = "As stated.")
  x$decide("C1", "endorse", actor = "A1", reason = "As stated.")
  x$decide("C1", "reject", actor = "A1", reason = "Not a headline claim.")
  x
}

test_that("without an origin nothing is flagged and origin columns are NA", {
  x <- make_origin_space()
  expect_equal(nrow(x$validate()), 0L)
  expect_true(all(is.na(x$decisions()$proposed_by)))
  s <- x$origin_summary()
  expect_equal(s[table == "all", no_origin], 3L)
})

test_that("validate() flags decisions without origin once one is recorded", {
  x <- make_origin_space()
  x$add_decision_origin(c("D1", "D2"), "A3", source_file = "p.json")
  v <- x$validate()
  expect_identical(v[check == "decision_without_origin", row], "D3")
  x$add_decision_origin("D9", "A9", accepted = "modified_by_author")
  v <- x$validate()
  expect_identical(v[check == "origin_unknown_decision", row], "D9")
  expect_identical(v[check == "origin_unknown_agent", row], "D9")
})

test_that("add_decision_origin() checks its input", {
  x <- make_origin_space()
  expect_error(
    x$add_decision_origin("D1", "A3", accepted = "yes"),
    "must be one of"
  )
  expect_error(x$add_decision_origin(c("D1", "D1"), "A3"), "already recorded")
  x$add_decision_origin("D1", "A3")
  expect_error(x$add_decision_origin("D1", "A3"), "already recorded")
  expect_error(x$add_decision_origin("D2", ""), "must name an agent")
  expect_error(
    x$add_decision_origin(c("D2", "D3"), c("A3", "A3", "A3")),
    "length 1 or 2"
  )
})

test_that("origin_summary() counts unchanged, modified and reversed", {
  x <- make_origin_space()
  x$add_decision_origin(c("D1", "D2"), "A3")
  x$add_decision_origin("D3", "A1", accepted = "modified_by_author")
  s <- x$origin_summary()
  expect_identical(
    s$table,
    c(
      "eligibility",
      "findings",
      "transformations",
      "claims",
      "relations",
      "all"
    )
  )
  expect_equal(s[table == "all", decisions], 3L)
  expect_equal(s[table == "all", unchanged], 2L)
  expect_equal(s[table == "all", modified], 1L)
  expect_equal(s[table == "claims", reversed_later], 1L)
  expect_equal(s[table == "findings", reversed_later], 0L)
  expect_equal(s[table == "eligibility", decisions], 0L)
})

test_that("read_register() reads decision_origin.csv only when present", {
  src <- bundled_registers("PA-2.4")
  tmp <- file.path(tempfile(), "PA-2.4")
  dir.create(tmp, recursive = TRUE)
  file.copy(list.files(src, full.names = TRUE), tmp)
  og <- file.path(tmp, "decision_origin.csv")
  lines <- readLines(og)
  writeLines(lines[-length(lines)], og)
  v <- read_register(tmp)$validate()
  expect_identical(v$check, "decision_without_origin")
  expect_identical(v$row, "D11")
  unlink(og)
  x <- read_register(tmp)
  expect_equal(nrow(x$validate()), 0L)
  expect_true(all(is.na(x$decisions()$proposed_by)))
  unlink(dirname(tmp), recursive = TRUE)
})
