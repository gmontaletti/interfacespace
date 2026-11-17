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
