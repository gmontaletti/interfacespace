# 1. reading a register folder -----

#' Read a workbook-format register folder into an interface space
#'
#' Builds an [InterfaceSpace] from a folder holding the six CSV tables of
#' the coding protocol: `agents.csv`, `findings.csv`, `transformations.csv`,
#' `claims.csv`, `relations.csv` and `decisions.csv` (see the data
#' dictionary in `system.file("extdata", "README.md", package =
#' "interfacespace")`). Rows are added as candidates and the decisions are
#' then replayed in file order, so every status is derived from the decision
#' log (latest decision wins). The `status` columns stored in the CSV files
#' are ignored; [register_counts()] and the tests confirm that the replay
#' reproduces them.
#'
#' Coding rule 12 (qualitative data compared across groups defined by a
#' quantitative measure) is detected as in the reference implementation:
#' a transformation is marked `partition = TRUE` when an `endorse` decision
#' whose reason mentions "Rule 12" lists its row `T:<new_finding>`.
#'
#' When the folder holds `decision_origin.csv` (columns `decision`,
#' `proposed_by`, `accepted`, `source_file`, `note`), it is read with
#' `add_decision_origin()`: `decisions()` then shows who proposed each
#' decision and whether the decision-maker changed the proposal, and
#' `validate()` reports decisions without an origin. The file is optional;
#' `decisions.csv` itself is never changed.
#'
#' The `rows` field of a decision is a `;`-separated list of codes. Because a
#' transformation output may be a free-text label that itself contains `;`,
#' adjacent pieces are rejoined until they match a registered row.
#'
#' @param dir Path to the register folder.
#' @param study Study identifier; defaults to the folder name.
#' @param strict Logical; passed to `InterfaceSpace$new()`. With `FALSE`,
#'   decisions that break an invariant are kept (with a warning) and reported
#'   by `validate()`.
#' @return An [InterfaceSpace] object.
#' @seealso [bundled_registers()], [register_counts()].
#' @examples
#' x <- read_register(bundled_registers("HLT-C2"))
#' x
#' x$counts()
#' x$joint_display()
#' @export
read_register <- function(
  dir,
  study = basename(normalizePath(dir)),
  strict = TRUE
) {
  .check_scalar_string(dir, "dir")
  if (!dir.exists(dir)) {
    stop("Register folder not found: ", dir, call. = FALSE)
  }
  tabs <- .read_register_tables(dir)
  x <- InterfaceSpace$new(study, strict = strict)

  # 1.1 agents -----
  ag <- tabs$agents
  for (i in seq_len(nrow(ag))) {
    x$add_agent(ag$code[i], ag$name[i], ag$type[i], ag$description[i])
  }

  # 1.2 findings -----
  fs <- tabs$findings
  for (i in seq_len(nrow(fs))) {
    x$add_finding(
      fs$code[i],
      fs$strand[i],
      fs$finding[i],
      where_to_check = fs$where_to_check[i],
      quote = fs$quote[i],
      proposed_by = fs$proposed_by[i]
    )
  }

  # 1.3 transformations, with rule 12 detected from decisions -----
  tr <- tabs$transformations
  dec <- tabs$decisions
  t_keys <- sprintf("T:%s", tr$new_finding)
  all_keys <- c(
    fs$code,
    tabs$claims$code,
    tabs$relations$code,
    t_keys,
    .reserved_rows
  )
  dec_rows <- lapply(dec$rows, .parse_rows, keys = all_keys)
  is_r12 <- dec$action == "endorse" &
    grepl("rule 12", dec$reason, ignore.case = TRUE)
  r12 <- unique(unlist(dec_rows[is_r12]))
  for (i in seq_len(nrow(tr))) {
    x$add_transformation(
      tr$new_finding[i],
      .split_codes(tr$made_from[i]),
      method = tr$method[i],
      done_by = tr$done_by[i],
      crosses_strand = .as_flag(tr$crosses_strand[i]),
      partition = t_keys[i] %in% r12,
      proposed_by = tr$proposed_by[i]
    )
  }

  # 1.4 claims and relations -----
  cl <- tabs$claims
  for (i in seq_len(nrow(cl))) {
    x$propose_claim(
      cl$code[i],
      cl$claim[i],
      rests_on = .split_codes(cl$rests_on[i]),
      fit = cl$fit[i],
      origin = cl$origin[i],
      location = cl$location[i],
      proposed_by = cl$proposed_by[i]
    )
  }
  rl <- tabs$relations
  for (i in seq_len(nrow(rl))) {
    x$relate(
      rl$from[i],
      rl$relation[i],
      rl$to[i],
      code = rl$code[i],
      basis = rl$basis[i],
      proposed_by = rl$proposed_by[i]
    )
  }

  # 1.5 replay decisions in order -----
  for (i in seq_len(nrow(dec))) {
    x$decide(
      dec_rows[[i]],
      dec$action[i],
      actor = dec$who[i],
      reason = dec$reason[i],
      date = dec$date[i],
      code = dec$code[i]
    )
  }

  # 1.6 decision origin (optional file) -----
  og <- .read_decision_origin(dir)
  if (!is.null(og) && nrow(og)) {
    x$add_decision_origin(
      og$decision,
      og$proposed_by,
      accepted = og$accepted,
      source_file = og$source_file,
      note = og$note
    )
  }
  x
}

# 2. bundled registers -----

#' Paths to the ten registers shipped with the package
#'
#' The package ships the registers of the ten studies recoded for the paper
#' (protocol in `system.file("extdata", "00_protocol.md", package =
#' "interfacespace")`). They are returned in the order used in the paper.
#'
#' @param id Optional study identifiers (e.g. `"HLT-C2"`); default all.
#' @return A named character vector of folder paths.
#' @examples
#' bundled_registers()
#' bundled_registers("HLT-C2")
#' @export
bundled_registers <- function(id = NULL) {
  root <- system.file("extdata", "registers", package = "interfacespace")
  if (!nzchar(root)) {
    stop("Bundled registers not found.", call. = FALSE)
  }
  ids <- c(
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
  )
  if (!is.null(id)) {
    bad <- setdiff(id, ids)
    if (length(bad)) {
      stop(
        "Unknown register id(s): ",
        paste(bad, collapse = ", "),
        ". Available: ",
        paste(ids, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
    ids <- id
  }
  stats::setNames(file.path(root, ids), ids)
}

# 3. internal helpers -----

.register_columns <- list(
  agents = c("code", "name", "type", "description"),
  findings = c(
    "code",
    "strand",
    "where_to_check",
    "finding",
    "quote",
    "proposed_by"
  ),
  transformations = c(
    "new_finding",
    "made_from",
    "method",
    "done_by",
    "crosses_strand",
    "proposed_by"
  ),
  claims = c(
    "code",
    "claim",
    "location",
    "rests_on",
    "fit",
    "origin",
    "proposed_by"
  ),
  relations = c("code", "from", "relation", "to", "basis", "proposed_by"),
  decisions = c("code", "date", "who", "action", "rows", "reason")
)

.read_register_tables <- function(dir) {
  out <- lapply(names(.register_columns), function(nm) {
    cols <- .register_columns[[nm]]
    path <- file.path(dir, paste0(nm, ".csv"))
    if (!file.exists(path)) {
      if (nm == "agents") {
        stop("agents.csv is missing in ", dir, call. = FALSE)
      }
      dt <- data.table::as.data.table(
        stats::setNames(rep(list(character()), length(cols)), cols)
      )
      return(dt)
    }
    dt <- data.table::fread(
      path,
      colClasses = "character",
      na.strings = NULL,
      encoding = "UTF-8",
      fill = TRUE
    )
    miss <- setdiff(cols, names(dt))
    if (length(miss)) {
      stop(
        nm,
        ".csv lacks column(s): ",
        paste(miss, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
    for (j in cols) {
      data.table::set(dt, which(is.na(dt[[j]])), j, "")
    }
    dt
  })
  stats::setNames(out, names(.register_columns))
}

# Read decision_origin.csv when present; NULL otherwise.
.read_decision_origin <- function(dir) {
  path <- file.path(dir, "decision_origin.csv")
  if (!file.exists(path)) {
    return(NULL)
  }
  dt <- data.table::fread(
    path,
    colClasses = "character",
    na.strings = NULL,
    encoding = "UTF-8",
    fill = TRUE
  )
  miss <- setdiff(.origin_columns, names(dt))
  if (length(miss)) {
    stop(
      "decision_origin.csv lacks column(s): ",
      paste(miss, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  for (j in .origin_columns) {
    data.table::set(dt, which(is.na(dt[[j]])), j, "")
  }
  dt[, .origin_columns, with = FALSE]
}

# Split a decision's rows field on ';', rejoining adjacent pieces until they
# match a known row key (transformation labels may contain ';').
.parse_rows <- function(x, keys) {
  parts <- strsplit(x, ";", fixed = TRUE)[[1L]]
  out <- character()
  i <- 1L
  n <- length(parts)
  while (i <= n) {
    j <- i
    cur <- trimws(parts[i])
    while (!cur %in% keys && j < n) {
      j <- j + 1L
      cur <- trimws(paste(parts[i:j], collapse = ";"))
    }
    if (cur %in% keys) {
      out <- c(out, cur)
      i <- j + 1L
    } else {
      out <- c(out, trimws(parts[i]))
      i <- i + 1L
    }
  }
  out[nzchar(out)]
}
