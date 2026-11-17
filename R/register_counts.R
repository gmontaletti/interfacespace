# 1. per-study counts -----

#' Per-study counts of one or more registers
#'
#' Computes, from endorsed rows only, the counts of section 7 of the coding
#' protocol for each study: headline claims endorsed, joint claims, claims in
#' at least one endorsed relation and their share, relations by type
#' (`covers`, `backs`, `clashes`) and claims with empty `rests_on`.
#'
#' @param x An [InterfaceSpace], a list of them, or a character vector of
#'   register folder paths (read with [read_register()]).
#' @param pooled Logical; when `TRUE` a final row `study = "pooled"` sums the
#'   counts across studies (the related share is recomputed on the totals).
#' @return A `data.table` with one row per study and the columns described
#'   in the `counts()` method of [InterfaceSpace].
#' @examples
#' cnt <- register_counts(bundled_registers(), pooled = TRUE)
#' cnt[, .(study, claims, joint, related, related_share, clashes)]
#' @export
register_counts <- function(x, pooled = FALSE) {
  x <- .as_space_list(x)
  out <- data.table::rbindlist(lapply(x, function(s) s$counts()))
  if (pooled && nrow(out)) {
    num <- setdiff(
      names(out)[vapply(out, is.numeric, logical(1))],
      "related_share"
    )
    tot <- out[, lapply(.SD, sum), .SDcols = num]
    tot[, `:=`(
      study = "pooled",
      joint_codes = NA_character_,
      related_share = round(100 * related / claims, 1)
    )]
    out <- data.table::rbindlist(list(out, tot), use.names = TRUE)
  }
  out[]
}

# 2. decision origin -----

#' Who proposed the recorded decisions, per study and table
#'
#' Counts, for each study and each table decided, the decisions proposed by
#' a model agent (default `A3`, the decision-proposal and consistency model)
#' and recorded unchanged, the decisions in which the decision-maker changed
#' the proposal or added an item (`modified`), those proposed by another
#' agent (`other`, e.g. `A4`, the main session in the first rounds), those
#' without a recorded origin, and the decisions recorded unchanged from
#' `agent` that a later decision reversed on at least one row
#' (`reversed_later`). The origin of the bundled registers is in
#' `decision_origin.csv`, derived by matching each decision against the
#' proposal files (`system.file("extdata", "decision_origin.py", package =
#' "interfacespace")`).
#'
#' @inheritParams register_counts
#' @param agent Code of the proposing agent (default `"A3"`).
#' @param pooled Logical; when `TRUE`, rows `study = "pooled"` sum the
#'   counts across studies for each table.
#' @return A `data.table` with columns `study`, `table` (`eligibility`,
#'   `findings`, `transformations`, `claims`, `relations`, `all`),
#'   `decisions`, `unchanged`, `modified`, `other`, `no_origin`,
#'   `reversed_later`. A decision on rows of several tables counts in each
#'   of them and once in `all`.
#' @seealso [read_register()], [InterfaceSpace] (method `origin_summary()`).
#' @examples
#' org <- decision_origin_summary(bundled_registers())
#' org[table == "all"]
#' @export
decision_origin_summary <- function(x, agent = "A3", pooled = FALSE) {
  x <- .as_space_list(x)
  out <- data.table::rbindlist(lapply(x, function(s) s$origin_summary(agent)))
  if (pooled && nrow(out)) {
    num <- setdiff(names(out), c("study", "table"))
    tot <- out[, lapply(.SD, sum), by = table, .SDcols = num]
    tot[, study := "pooled"]
    out <- data.table::rbindlist(list(out, tot), use.names = TRUE)
  }
  out[]
}

# 3. internal helpers -----

# An InterfaceSpace, a list of them, or register paths -> list of spaces.
.as_space_list <- function(x) {
  if (inherits(x, "InterfaceSpace")) {
    x <- list(x)
  }
  if (is.character(x)) {
    nms <- if (is.null(names(x))) basename(x) else names(x)
    x <- Map(function(d, s) read_register(d, study = s), x, nms)
  }
  if (!is.list(x) || !all(vapply(x, inherits, logical(1), "InterfaceSpace"))) {
    stop(
      "`x` must be an InterfaceSpace, a list of them, or register paths.",
      call. = FALSE
    )
  }
  x
}
