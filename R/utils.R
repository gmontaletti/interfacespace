# 1. vocabularies -----

.agent_types <- c("person", "model", "algorithm")
.strands <- c("Q", "N")
.fits <- c("confirm", "expand", "discord", "single-strand")
.relation_types <- c("backs", "clashes", "covers")
.actions <- c("endorse", "reject")
.reserved_rows <- c("eligibility")

# 2. small helpers -----

# Split a ';'-separated code list into a trimmed character vector.
.split_codes <- function(x) {
  if (length(x) == 0L || is.na(x) || !nzchar(trimws(x))) {
    return(character())
  }
  out <- trimws(strsplit(x, ";", fixed = TRUE)[[1L]])
  out[nzchar(out)]
}

# Collapse a character vector into a ';'-separated code list.
.join_codes <- function(x) {
  x <- as.character(x)
  x <- trimws(x[!is.na(x)])
  paste(x[nzchar(x)], collapse = ";")
}

# Normalise a scalar text argument: NULL / NA -> "".
.text <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[1L])) {
    return("")
  }
  as.character(x[1L])
}

.is_blank <- function(x) {
  is.null(x) || length(x) == 0L || is.na(x[1L]) || !nzchar(trimws(x[1L]))
}

.check_scalar_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    stop(
      "`",
      arg,
      "` must be a single non-empty character string.",
      call. = FALSE
    )
  }
  invisible(x)
}

# Next code for a prefix ("F", "C", "R", "D"), never reusing numbers.
.next_code <- function(prefix, existing) {
  pat <- paste0("^", prefix, "([0-9]+)$")
  nums <- suppressWarnings(as.integer(sub(
    pat,
    "\\1",
    existing[grepl(pat, existing)]
  )))
  paste0(prefix, if (length(nums)) max(nums) + 1L else 1L)
}

# Order codes by their numeric part (C2 before C10).
.order_codes <- function(x) {
  num <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", x)))
  x[order(num, x)]
}

# Fit values: "" and NA mean not recorded.
.normalise_fit <- function(fit) {
  if (.is_blank(fit)) {
    return(NA_character_)
  }
  fit <- trimws(as.character(fit[1L]))
  if (!fit %in% .fits) {
    stop(
      "`fit` must be one of ",
      paste(.fits, collapse = ", "),
      " (or NA when not recorded); got '",
      fit,
      "'.",
      call. = FALSE
    )
  }
  fit
}

# yes / no / logical -> logical.
.as_flag <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NA)
  }
  if (is.logical(x)) {
    return(x[1L])
  }
  x <- tolower(trimws(as.character(x[1L])))
  if (x %in% c("yes", "true", "y", "1")) {
    return(TRUE)
  }
  if (x %in% c("no", "false", "n", "0")) {
    return(FALSE)
  }
  NA
}

# 3. empty tables -----

.empty_tables <- function() {
  list(
    agents = data.table::data.table(
      code = character(),
      name = character(),
      type = character(),
      description = character()
    ),
    findings = data.table::data.table(
      code = character(),
      strand = character(),
      where_to_check = character(),
      finding = character(),
      quote = character(),
      proposed_by = character()
    ),
    transformations = data.table::data.table(
      new_finding = character(),
      made_from = character(),
      method = character(),
      done_by = character(),
      crosses_strand = logical(),
      partition = logical(),
      proposed_by = character()
    ),
    claims = data.table::data.table(
      code = character(),
      claim = character(),
      location = character(),
      rests_on = character(),
      fit = character(),
      origin = character(),
      proposed_by = character()
    ),
    relations = data.table::data.table(
      code = character(),
      from = character(),
      relation = character(),
      to = character(),
      basis = character(),
      proposed_by = character()
    ),
    decisions = data.table::data.table(
      code = character(),
      date = character(),
      actor = character(),
      action = character(),
      rows = character(),
      reason = character()
    ),
    decision_rows = data.table::data.table(
      decision = character(),
      seq = integer(),
      row = character(),
      action = character()
    )
  )
}
