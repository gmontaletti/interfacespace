# 1. per-study counts reproduce counts_by_study.csv -----

ref <- data.table::fread(
  test_path("counts_by_study.csv"),
  colClasses = list(character = "joint_codes")
)
cnt <- register_counts(bundled_registers())

test_that("ten bundled registers are read in the paper order", {
  expect_identical(cnt$study, ref$study)
  expect_length(bundled_registers(), 10L)
  expect_error(bundled_registers("XX-1"), "Unknown register")
})

cols <- c("claims", "joint", "related", "related_share", "relations",
          "covers", "backs", "clashes", "unsupported_claims")

for (id in ref$study) {
  test_that(paste("counts reproduce counts_by_study.csv for", id), {
    got <- cnt[study == id]
    exp <- ref[study == id]
    for (v in cols) {
      expect_equal(got[[v]], exp[[v]], label = paste(id, v))
    }
    for (v in c("findings", "findings_Q", "findings_N", "transformations",
                "joint_codes", "rows_total", "rows_rejected")) {
      expect_equal(got[[v]], exp[[v]], label = paste(id, v))
    }
  })
}

test_that("pooled totals match the paper", {
  pooled <- register_counts(bundled_registers(), pooled = TRUE)[
    study == "pooled"]
  expect_equal(pooled$claims, 532L)
  expect_equal(pooled$joint, 34L)
  expect_equal(pooled$related, 225L)
  expect_equal(pooled$clashes, 0L)
  expect_equal(pooled$related_share, round(100 * 225 / 532, 1))
})

# 2. replay and checks on the bundled registers -----

test_that("replayed statuses equal the status columns of the CSV files", {
  for (p in bundled_registers()) {
    x <- read_register(p)
    for (tbl in c("findings", "claims", "relations")) {
      csv <- data.table::fread(file.path(p, paste0(tbl, ".csv")),
                               colClasses = "character")
      got <- x[[tbl]]()
      expect_identical(got$status[match(csv$code, got$code)], csv$status,
                       label = paste(basename(p), tbl))
    }
    csv <- data.table::fread(file.path(p, "transformations.csv"),
                             colClasses = "character")
    got <- x$transformations()
    expect_identical(got$status[match(csv$new_finding, got$new_finding)],
                     csv$status, label = paste(basename(p), "transformations"))
  }
})

test_that("bundled registers pass validate()", {
  for (p in bundled_registers()) {
    expect_equal(nrow(read_register(p)$validate()), 0L,
                 label = basename(p))
  }
})

test_that("rule 12 is detected from decisions", {
  x <- read_register(bundled_registers("HLT-C5"))
  tr <- x$transformations("endorsed")
  expect_true(all(tr[new_finding %in% sprintf("F%d", 15:19), partition]))
  y <- read_register(bundled_registers("MD-C8"))
  expect_false(any(y$transformations()$partition))
})

test_that("transformation labels containing ';' are parsed in decisions", {
  x <- read_register(bundled_registers("HLT-C15"))
  tr <- x$transformations()
  expect_equal(nrow(tr), 2L)
  expect_true(all(tr$status == "rejected"))
})

test_that("joint display and outputs work on HLT-C2", {
  x <- read_register(bundled_registers("HLT-C2"))
  jd <- x$joint_display()
  expect_identical(jd$claim, c("C1", "C3", "C6"))
  expect_true(all(nzchar(jd$q_roots) & nzchar(jd$n_roots)))
  skip_if_not_installed("jsonlite")
  js <- jsonlite::fromJSON(x$to_json())
  expect_equal(js$study, "HLT-C2")
  expect_equal(js$counts$joint, 3L)
  skip_if_not_installed("igraph")
  g <- x$as_igraph(endorsed_only = TRUE)
  expect_s3_class(g, "igraph")
  expect_true(all(c("C1", "F1") %in% igraph::V(g)$name))
})
