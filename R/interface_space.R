#' Interface space: a register of joint qualitative-quantitative claims
#'
#' @description
#' An `InterfaceSpace` holds the register of a mixed methods evaluation:
#' agents, findings (strand `Q` or `N`), transformations of findings,
#' headline claims, relations among claims and the decisions, with reasons,
#' that change the status of every row. It is the computable form of the
#' workbook described in the package vignette.
#'
#' @details
#' **Status.** Every row is born a `candidate`. Status changes only through
#' decisions, which are append-only: they are never edited or deleted, and a
#' later decision on the same row supersedes an earlier one (latest wins).
#' A decision needs an actor registered as a `person` and a non-empty reason.
#' A row proposed by a `model` or an `algorithm` agent enters as a candidate
#' and cannot be endorsed in the call that creates it. Signing is open:
#' rows may remain candidates.
#'
#' **Rows decided.** Decisions refer to rows by code: findings (`F1`),
#' claims (`C1`), relations (`R1`) and transformations (`T:` followed by the
#' code of the output finding, e.g. `T:F18`). The study-level key
#' `"eligibility"` is also accepted.
#'
#' **Endorsing and jointness.** Endorsing a row means that the decision-maker
#' accepts it as correctly recorded; it does not require dual-strand
#' grounding. Jointness is computed: a claim is joint when its `rests_on`,
#' traced back through endorsed transformations to endorsed root findings,
#' includes at least one `Q` and one `N` root. A transformation with
#' `partition = TRUE` (coding rule 12: qualitative data compared across
#' groups defined by a quantitative measure) makes its output finding a root
#' of its own strand in addition to the roots of its inputs; other
#' transformations pass on only the roots of their inputs. A theme plus the
#' percentage computed from that same theme therefore has one root, not two.
#'
#' @section Strict and lenient mode:
#' With `strict = TRUE` (default) a decision that breaks an invariant
#' (empty reason, actor not a person, unknown row) raises an error. With
#' `strict = FALSE` it is recorded with a warning, and `validate()` reports it.
#' Lenient mode exists to audit registers kept outside the package.
#'
#' @examples
#' x <- InterfaceSpace$new("demo")
#' x$add_agent("A1", "Analyst", "person")
#' x$add_agent("A2", "LLM extractor", "model")
#' x$add_finding("F1", "Q", "Users describe growing confidence.",
#'               where_to_check = "Interviews, p. 7", proposed_by = "A2")
#' x$add_finding("F2", "N", "Confidence scale rises, d = 0.45.",
#'               where_to_check = "Table 2", proposed_by = "A2")
#' x$propose_claim("C1", "The service raises confidence.",
#'                 rests_on = c("F1", "F2"), fit = "confirm",
#'                 proposed_by = "A2")
#' x$decide(c("F1", "F2", "C1"), "endorse", actor = "A1",
#'          reason = "Recorded as stated in the abstract and results.")
#' x$claims()
#' x$is_joint("C1")
#' x$counts()
#' x$validate()
#' @export
InterfaceSpace <- R6::R6Class(
  "InterfaceSpace",
  cloneable = FALSE,

  public = list(
    # 1. construction -----

    #' @description Create an empty interface space.
    #' @param study Character scalar, the study identifier.
    #' @param strict Logical. See section *Strict and lenient mode*.
    #' @return A new `InterfaceSpace` object.
    initialize = function(study, strict = TRUE) {
      .check_scalar_string(study, "study")
      stopifnot(is.logical(strict), length(strict) == 1L, !is.na(strict))
      private$study <- study
      private$strict <- strict
      private$tab <- .empty_tables()
      invisible(self)
    },

    #' @description Print a short summary of the space.
    #' @param ... Ignored.
    print = function(...) {
      st <- private$status_table()
      n_end <- function(tbl) sum(st$table == tbl & st$status == "endorsed")
      cat("<InterfaceSpace> ", private$study, "\n", sep = "")
      cat("  agents:          ", nrow(private$tab$agents), "\n", sep = "")
      for (tbl in c("findings", "transformations", "claims", "relations")) {
        cat(sprintf(
          "  %-16s %d (%d endorsed)\n",
          paste0(tbl, ":"),
          sum(st$table == tbl),
          n_end(tbl)
        ))
      }
      cat("  decisions:       ", nrow(private$tab$decisions), "\n", sep = "")
      invisible(self)
    },

    #' @description The study identifier.
    #' @return Character scalar.
    study_id = function() private$study,

    # 2. adding rows -----

    #' @description Register an agent (person, model or algorithm).
    #' @param code Agent code, e.g. `"A1"`.
    #' @param name Name of the person, or model / algorithm identifier.
    #' @param type One of `"person"`, `"model"`, `"algorithm"`.
    #' @param description Free text (role, model version, prompt version).
    #' @return The object, invisibly.
    add_agent = function(
      code,
      name,
      type = c("person", "model", "algorithm"),
      description = ""
    ) {
      .check_scalar_string(code, "code")
      type <- match.arg(type)
      if (code %in% private$tab$agents$code) {
        stop("Agent code '", code, "' is already registered.", call. = FALSE)
      }
      private$tab$agents <- data.table::rbindlist(list(
        private$tab$agents,
        list(
          code = code,
          name = .text(name),
          type = type,
          description = .text(description)
        )
      ))
      invisible(self)
    },

    #' @description Register a finding. It enters as a candidate.
    #' @param code Finding code (`"F1"`); `NULL` assigns the next free one.
    #' @param strand `"Q"` (qualitative) or `"N"` (quantitative).
    #' @param finding The finding, in one sentence.
    #' @param where_to_check Page, table or section where it can be checked.
    #' @param quote Short verbatim quote.
    #' @param proposed_by Code of a registered agent.
    #' @param endorse `NULL`, or a reason: endorse the row in the same call.
    #'   Allowed only when `proposed_by` is a person.
    #' @param date Date of the endorsement (character, default today).
    #' @return The object, invisibly.
    add_finding = function(
      code = NULL,
      strand = c("Q", "N"),
      finding,
      where_to_check = "",
      quote = "",
      proposed_by,
      endorse = NULL,
      date = NULL
    ) {
      strand <- match.arg(strand)
      .check_scalar_string(finding, "finding")
      code <- private$new_row_code(code, "F")
      private$assert_agent(proposed_by, "proposed_by")
      private$assert_can_endorse_at_creation(proposed_by, endorse)
      private$tab$findings <- data.table::rbindlist(list(
        private$tab$findings,
        list(
          code = code,
          strand = strand,
          where_to_check = .text(where_to_check),
          finding = finding,
          quote = .text(quote),
          proposed_by = proposed_by
        )
      ))
      private$endorse_at_creation(code, proposed_by, endorse, date)
      invisible(self)
    },

    #' @description Register a transformation that produces a finding from
    #'   other findings (e.g. counting a theme, describing a cluster).
    #' @param new_finding Code of the output finding. A free-text label is
    #'   accepted for an output that is not registered as a finding;
    #'   `validate()` reports it unless the row is rejected.
    #' @param made_from Codes of the input findings (character vector).
    #' @param method The method, in plain words.
    #' @param done_by Code of the agent that did the transformation (e.g. the
    #'   study's authors), or `""`.
    #' @param crosses_strand Logical; `NULL` computes it from the strands of
    #'   input and output findings.
    #' @param partition Logical. `TRUE` for a coding rule 12 transformation:
    #'   qualitative data compared across groups defined by a quantitative
    #'   measure. The output finding then counts as a root of its own strand.
    #' @param proposed_by Code of a registered agent.
    #' @param endorse `NULL`, or a reason (see `add_finding()`).
    #' @param date Date of the endorsement (character, default today).
    #' @return The object, invisibly.
    add_transformation = function(
      new_finding,
      made_from,
      method = "",
      done_by = "",
      crosses_strand = NULL,
      partition = FALSE,
      proposed_by,
      endorse = NULL,
      date = NULL
    ) {
      .check_scalar_string(new_finding, "new_finding")
      made_from <- unique(as.character(made_from))
      if (!length(made_from)) {
        stop("`made_from` must list at least one finding.", call. = FALSE)
      }
      unknown <- setdiff(made_from, private$tab$findings$code)
      if (length(unknown)) {
        stop(
          "Unknown finding(s) in `made_from`: ",
          paste(unknown, collapse = ", "),
          ".",
          call. = FALSE
        )
      }
      if (new_finding %in% made_from) {
        stop(
          "A transformation cannot be made from its own output.",
          call. = FALSE
        )
      }
      if (new_finding %in% private$tab$transformations$new_finding) {
        stop(
          "A transformation producing '",
          new_finding,
          "' is already registered.",
          call. = FALSE
        )
      }
      stopifnot(
        is.logical(partition),
        length(partition) == 1L,
        !is.na(partition)
      )
      if (!.is_blank(done_by)) {
        private$assert_agent(done_by, "done_by")
      }
      private$assert_agent(proposed_by, "proposed_by")
      private$assert_can_endorse_at_creation(proposed_by, endorse)
      if (is.null(crosses_strand)) {
        fs <- private$tab$findings
        out_strand <- fs[code == new_finding, strand]
        crosses_strand <- if (length(out_strand)) {
          any(fs[code %in% made_from, strand] != out_strand)
        } else {
          NA
        }
      }
      private$tab$transformations <- data.table::rbindlist(list(
        private$tab$transformations,
        list(
          new_finding = new_finding,
          made_from = .join_codes(made_from),
          method = .text(method),
          done_by = .text(done_by),
          crosses_strand = .as_flag(crosses_strand),
          partition = partition,
          proposed_by = proposed_by
        )
      ))
      private$endorse_at_creation(
        sprintf("T:%s", new_finding),
        proposed_by,
        endorse,
        date
      )
      invisible(self)
    },

    #' @description Propose a headline claim. It enters as a candidate.
    #' @param code Claim code (`"C1"`); `NULL` assigns the next free one.
    #' @param claim The claim, as stated.
    #' @param rests_on Codes of the findings the text uses for the claim
    #'   (character vector, possibly empty).
    #' @param fit One of `"confirm"`, `"expand"`, `"discord"`,
    #'   `"single-strand"`, or `NA` when not recorded.
    #' @param origin Where the claim comes from (free text, e.g. `"data"`).
    #' @param location Where the claim is stated (abstract, conclusions, page).
    #' @param proposed_by Code of a registered agent.
    #' @param endorse `NULL`, or a reason (see `add_finding()`).
    #' @param date Date of the endorsement (character, default today).
    #' @return The object, invisibly.
    propose_claim = function(
      code = NULL,
      claim,
      rests_on = character(),
      fit = NA,
      origin = "",
      location = "",
      proposed_by,
      endorse = NULL,
      date = NULL
    ) {
      .check_scalar_string(claim, "claim")
      rests_on <- unique(as.character(rests_on))
      unknown <- setdiff(rests_on, private$tab$findings$code)
      if (length(unknown)) {
        stop(
          "Unknown finding(s) in `rests_on`: ",
          paste(unknown, collapse = ", "),
          ".",
          call. = FALSE
        )
      }
      fit <- .normalise_fit(fit)
      code <- private$new_row_code(code, "C")
      private$assert_agent(proposed_by, "proposed_by")
      private$assert_can_endorse_at_creation(proposed_by, endorse)
      private$tab$claims <- data.table::rbindlist(list(
        private$tab$claims,
        list(
          code = code,
          claim = claim,
          location = .text(location),
          rests_on = .join_codes(rests_on),
          fit = fit,
          origin = .text(origin),
          proposed_by = proposed_by
        )
      ))
      private$endorse_at_creation(code, proposed_by, endorse, date)
      invisible(self)
    },

    #' @description Record a relation between two claims. It enters as a
    #'   candidate.
    #' @param from Code of the first claim.
    #' @param relation `"backs"` (gives reasons for), `"clashes"` (both cannot
    #'   hold) or `"covers"` (is the broader claim that includes).
    #' @param to Code of the second claim.
    #' @param code Relation code (`"R1"`); `NULL` assigns the next free one.
    #' @param basis Quote or page showing the link.
    #' @param proposed_by Code of a registered agent.
    #' @param endorse `NULL`, or a reason (see `add_finding()`).
    #' @param date Date of the endorsement (character, default today).
    #' @return The object, invisibly.
    relate = function(
      from,
      relation = c("backs", "clashes", "covers"),
      to,
      code = NULL,
      basis = "",
      proposed_by,
      endorse = NULL,
      date = NULL
    ) {
      relation <- match.arg(relation)
      .check_scalar_string(from, "from")
      .check_scalar_string(to, "to")
      unknown <- setdiff(c(from, to), private$tab$claims$code)
      if (length(unknown)) {
        stop(
          "Unknown claim(s): ",
          paste(unknown, collapse = ", "),
          ".",
          call. = FALSE
        )
      }
      code <- private$new_row_code(code, "R")
      private$assert_agent(proposed_by, "proposed_by")
      private$assert_can_endorse_at_creation(proposed_by, endorse)
      private$tab$relations <- data.table::rbindlist(list(
        private$tab$relations,
        list(
          code = code,
          from = from,
          relation = relation,
          to = to,
          basis = .text(basis),
          proposed_by = proposed_by
        )
      ))
      private$endorse_at_creation(code, proposed_by, endorse, date)
      invisible(self)
    },

    # 3. decisions -----

    #' @description Record a decision. Decisions are append-only; a later
    #'   decision on the same row supersedes an earlier one.
    #' @param rows Codes of the rows decided: findings, claims, relations,
    #'   `T:<new_finding>` for transformations, or `"eligibility"`.
    #' @param action `"endorse"` or `"reject"`.
    #' @param actor Code of an agent of type person.
    #' @param reason The reason, written out (required).
    #' @param date Date (character, default today).
    #' @param code Decision code (`"D1"`); `NULL` assigns the next free one.
    #' @return The object, invisibly.
    decide = function(
      rows,
      action = c("endorse", "reject"),
      actor,
      reason,
      date = NULL,
      code = NULL
    ) {
      action <- match.arg(action)
      rows <- unique(trimws(as.character(rows)))
      rows <- rows[nzchar(rows)]
      if (!length(rows)) {
        stop("`rows` must name at least one row.", call. = FALSE)
      }
      if (is.null(code)) {
        code <- .next_code("D", private$tab$decisions$code)
      }
      .check_scalar_string(code, "code")
      if (code %in% private$tab$decisions$code) {
        stop("Decision code '", code, "' is already used.", call. = FALSE)
      }
      problems <- character()
      if (.is_blank(reason)) {
        problems <- c(problems, "a decision needs a written reason")
      }
      ag <- private$tab$agents
      if (.is_blank(actor) || !actor %in% ag$code) {
        problems <- c(problems, "the actor must be a registered agent")
      } else if (ag[code == actor, type] != "person") {
        problems <- c(
          problems,
          paste0(
            "the actor must be a person (agent '",
            actor,
            "' is a ",
            ag[code == actor, type],
            ")"
          )
        )
      }
      unknown <- setdiff(rows, c(private$row_keys(), .reserved_rows))
      if (length(unknown)) {
        problems <- c(
          problems,
          paste0("unknown row(s): ", paste(unknown, collapse = ", "))
        )
      }
      if (length(problems)) {
        msg <- paste0(
          "Decision ",
          code,
          ": ",
          paste(problems, collapse = "; "),
          "."
        )
        if (private$strict) {
          stop(msg, call. = FALSE)
        }
        warning(msg, call. = FALSE)
      }
      if (is.null(date)) {
        date <- format(Sys.Date())
      }
      private$tab$decisions <- data.table::rbindlist(list(
        private$tab$decisions,
        list(
          code = code,
          date = .text(date),
          actor = .text(actor),
          action = action,
          rows = .join_codes(rows),
          reason = .text(reason)
        )
      ))
      seq_no <- nrow(private$tab$decisions)
      private$tab$decision_rows <- data.table::rbindlist(list(
        private$tab$decision_rows,
        data.table::data.table(
          decision = code,
          seq = seq_no,
          row = rows,
          action = action
        )
      ))
      invisible(self)
    },

    # 4. tables -----

    #' @description Agents table.
    #' @return A `data.table`.
    agents = function() data.table::copy(private$tab$agents),

    #' @description Findings with their current status.
    #' @param status Optional filter: any of `"candidate"`, `"endorsed"`,
    #'   `"rejected"`.
    #' @return A `data.table`.
    findings = function(status = NULL) {
      out <- data.table::copy(private$tab$findings)
      out[, status := private$status_of(code)]
      private$filter_status(out, status)
    },

    #' @description Transformations with their current status (row key
    #'   `T:<new_finding>`).
    #' @param status Optional status filter.
    #' @return A `data.table`.
    transformations = function(status = NULL) {
      out <- data.table::copy(private$tab$transformations)
      out[, status := private$status_of(sprintf("T:%s", new_finding))]
      private$filter_status(out, status)
    },

    #' @description Claims with their current status and computed jointness.
    #' @param status Optional status filter.
    #' @return A `data.table`; column `joint` is `TRUE` when the claim's
    #'   roots include both strands.
    claims = function(status = NULL) {
      out <- data.table::copy(private$tab$claims)
      out[, status := private$status_of(code)]
      out[, joint := self$is_joint(code)]
      private$filter_status(out, status)
    },

    #' @description Relations with their current status.
    #' @param status Optional status filter.
    #' @return A `data.table`.
    relations = function(status = NULL) {
      out <- data.table::copy(private$tab$relations)
      out[, status := private$status_of(code)]
      private$filter_status(out, status)
    },

    #' @description The decision log, in the order recorded.
    #' @return A `data.table`.
    decisions = function() data.table::copy(private$tab$decisions),

    # 5. roots and jointness -----

    #' @description Root findings of claims or findings, traced through
    #'   endorsed transformations to endorsed findings.
    #' @param codes Claim or finding codes. Default: all endorsed claims.
    #' @return A `data.table` with columns `code`, `root`, `strand`.
    roots = function(codes = NULL) {
      if (is.null(codes)) {
        codes <- self$claims("endorsed")$code
      }
      ctx <- private$root_context()
      cl <- private$tab$claims
      res <- lapply(codes, function(x) {
        start <- if (x %in% cl$code) {
          .split_codes(cl[code == x, rests_on])
        } else {
          x
        }
        r <- unique(unlist(lapply(start, private$finding_roots, ctx = ctx)))
        if (!length(r)) {
          return(NULL)
        }
        data.table::data.table(
          code = x,
          root = .order_codes(r),
          strand = unname(ctx$strand[.order_codes(r)])
        )
      })
      out <- data.table::rbindlist(res)
      if (!nrow(out)) {
        out <- data.table::data.table(
          code = character(),
          root = character(),
          strand = character()
        )
      }
      out
    },

    #' @description Jointness of claims: at least one `Q` and one `N` root.
    #' @param codes Claim codes. Default: all endorsed claims.
    #' @return A named logical vector.
    is_joint = function(codes = NULL) {
      if (is.null(codes)) {
        codes <- self$claims("endorsed")$code
      }
      if (!length(codes)) {
        return(stats::setNames(logical(), character()))
      }
      r <- self$roots(codes)
      both <- r[, .(joint = all(c("Q", "N") %in% strand)), by = code]
      out <- stats::setNames(rep(FALSE, length(codes)), codes)
      out[both[joint == TRUE, code]] <- TRUE
      out
    },

    # 6. counts and checks -----

    #' @description Counts from endorsed rows (protocol section 7).
    #' @return A one-row `data.table`: `study`, `findings`, `findings_Q`,
    #'   `findings_N`, `transformations`, `claims` (headline claims
    #'   endorsed), `joint`, `joint_codes`, `related` (endorsed claims in at
    #'   least one endorsed relation), `related_share` (percent, one
    #'   decimal), `relations`, `covers`, `backs`, `clashes`,
    #'   `unsupported_claims` (endorsed claims with empty `rests_on`),
    #'   `rows_total`, `rows_rejected`.
    counts = function() {
      f <- self$findings()
      tr <- self$transformations()
      cl <- self$claims()
      rl <- self$relations()
      f_end <- f[status == "endorsed"]
      c_end <- cl[status == "endorsed"]
      r_end <- rl[status == "endorsed"]
      related <- intersect(unique(c(r_end$from, r_end$to)), c_end$code)
      n_claims <- nrow(c_end)
      all_status <- c(f$status, tr$status, cl$status, rl$status)
      data.table::data.table(
        study = private$study,
        findings = nrow(f_end),
        findings_Q = sum(f_end$strand == "Q"),
        findings_N = sum(f_end$strand == "N"),
        transformations = sum(tr$status == "endorsed"),
        claims = n_claims,
        joint = sum(c_end$joint),
        joint_codes = .join_codes(.order_codes(c_end[joint == TRUE, code])),
        related = length(related),
        related_share = if (n_claims) {
          round(100 * length(related) / n_claims, 1)
        } else {
          NA_real_
        },
        relations = nrow(r_end),
        covers = sum(r_end$relation == "covers"),
        backs = sum(r_end$relation == "backs"),
        clashes = sum(r_end$relation == "clashes"),
        unsupported_claims = sum(!nzchar(c_end$rests_on)),
        rows_total = length(all_status),
        rows_rejected = sum(all_status == "rejected")
      )
    },

    #' @description Check the space and list violations. Checks never change
    #'   content.
    #' @return A `data.table` with columns `check`, `row`, `note`; zero rows
    #'   when the space is well built. Checks: `relation_nonendorsed_claim`
    #'   (endorsed relation linking a claim that is not endorsed),
    #'   `decision_without_reason`, `decision_not_by_person` (a machine or
    #'   unknown actor signed), `decision_unknown_row`,
    #'   `joint_claim_single_strand_fit` (endorsed joint claim with fit
    #'   single-strand or not recorded), `endorsed_claim_nonendorsed_finding`
    #'   (endorsed claim resting on a finding that is not endorsed),
    #'   `transformation_output_unregistered`, `partition_not_crossing`.
    validate = function() {
      v <- list()
      add <- function(check, row, note) {
        if (length(row)) {
          v[[length(v) + 1L]] <<- data.table::data.table(
            check = check,
            row = row,
            note = note
          )
        }
      }
      cl <- self$claims()
      rl <- self$relations()
      fs <- self$findings()
      tr <- self$transformations()
      dec <- private$tab$decisions
      ag <- private$tab$agents
      c_end <- cl[status == "endorsed", code]
      # endorsed relations must link endorsed claims
      bad <- rl[status == "endorsed" & (!from %in% c_end | !to %in% c_end)]
      add(
        "relation_nonendorsed_claim",
        bad$code,
        sprintf(
          "%s %s %s: an endpoint is not an endorsed claim",
          bad$from,
          bad$relation,
          bad$to
        )
      )
      # decisions need reasons and a person as actor
      bad <- dec[!nzchar(trimws(reason))]
      add("decision_without_reason", bad$code, "empty reason")
      persons <- ag[type == "person", code]
      bad <- dec[!actor %in% persons]
      add(
        "decision_not_by_person",
        bad$code,
        sprintf("actor '%s' is not a registered person", bad$actor)
      )
      dr <- private$tab$decision_rows
      bad <- dr[!row %in% c(private$row_keys(), .reserved_rows)]
      add(
        "decision_unknown_row",
        bad$decision,
        sprintf("row '%s' is not registered", bad$row)
      )
      # joint claims need a dual-strand fit
      bad <- cl[
        status == "endorsed" &
          joint == TRUE &
          (is.na(fit) | fit == "single-strand")
      ]
      add(
        "joint_claim_single_strand_fit",
        bad$code,
        sprintf(
          "joint claim with fit '%s'",
          ifelse(is.na(bad$fit), "", bad$fit)
        )
      )
      # endorsed claims should rest on endorsed findings
      f_end <- fs[status == "endorsed", code]
      ce <- cl[status == "endorsed" & nzchar(rests_on)]
      if (nrow(ce)) {
        long <- ce[, .(finding = .split_codes(rests_on)), by = code]
        bad <- long[!finding %in% f_end]
        add(
          "endorsed_claim_nonendorsed_finding",
          bad$code,
          sprintf("rests on %s, which is not endorsed", bad$finding)
        )
      }
      # transformation outputs and partitions
      bad <- tr[status != "rejected" & !new_finding %in% fs$code]
      add(
        "transformation_output_unregistered",
        sprintf("T:%s", bad$new_finding),
        "output is not a registered finding"
      )
      bad <- tr[status != "rejected" & partition & crosses_strand %in% FALSE]
      add(
        "partition_not_crossing",
        sprintf("T:%s", bad$new_finding),
        "partition (rule 12) transformation recorded as not crossing strands"
      )
      if (!length(v)) {
        return(data.table::data.table(
          check = character(),
          row = character(),
          note = character()
        ))
      }
      data.table::rbindlist(v)
    },

    # 7. outputs -----

    #' @description Joint display: for each endorsed claim, its qualitative
    #'   and quantitative roots side by side (workbook Table 7).
    #' @param joint_only Logical; keep only joint claims (default `TRUE`).
    #' @return A `data.table` with columns `claim`, `statement`, `q_roots`,
    #'   `q_findings`, `n_roots`, `n_findings`, `fit`, `joint`.
    joint_display = function(joint_only = TRUE) {
      cl <- self$claims("endorsed")
      if (joint_only) {
        cl <- cl[joint == TRUE]
      }
      fs <- private$tab$findings
      r <- self$roots(cl$code)
      txt <- function(codes) {
        if (!length(codes)) {
          return("")
        }
        paste0(codes, ": ", fs$finding[match(codes, fs$code)], collapse = " | ")
      }
      rows <- lapply(cl$code, function(x) {
        q <- r[code == x & strand == "Q", root]
        n <- r[code == x & strand == "N", root]
        list(
          q_roots = .join_codes(q),
          q_findings = txt(q),
          n_roots = .join_codes(n),
          n_findings = txt(n)
        )
      })
      out <- data.table::data.table(claim = cl$code, statement = cl$claim)
      if (nrow(out)) {
        out <- cbind(out, data.table::rbindlist(rows))
      } else {
        out[, `:=`(
          q_roots = character(),
          q_findings = character(),
          n_roots = character(),
          n_findings = character()
        )]
      }
      out[, `:=`(fit = cl$fit, joint = cl$joint)]
      out[]
    },

    #' @description Graph of the space (requires the igraph package).
    #'   Vertices are findings and claims; edges are `made_from` (input to
    #'   output finding), `rests_on` (finding to claim) and relations
    #'   (`backs`, `clashes`, `covers`, claim to claim).
    #' @param endorsed_only Logical; keep only endorsed rows (default
    #'   `FALSE`).
    #' @return An `igraph` object.
    as_igraph = function(endorsed_only = FALSE) {
      if (!requireNamespace("igraph", quietly = TRUE)) {
        stop("Package 'igraph' is required for as_igraph().", call. = FALSE)
      }
      keep <- if (endorsed_only) "endorsed" else NULL
      fs <- self$findings(keep)
      cl <- self$claims(keep)
      tr <- self$transformations(keep)
      rl <- self$relations(keep)
      v <- data.table::rbindlist(list(
        fs[, .(
          name = code,
          kind = "finding",
          strand,
          status,
          text = finding,
          joint = NA
        )],
        cl[, .(
          name = code,
          kind = "claim",
          strand = NA_character_,
          status,
          text = claim,
          joint
        )]
      ))
      e_tr <- tr[,
        .(from = .split_codes(made_from), type = "made_from"),
        by = .(to = new_finding, status)
      ]
      e_cl <- cl[nzchar(rests_on),
        .(from = .split_codes(rests_on), type = "rests_on"),
        by = .(to = code, status)
      ]
      e_rl <- rl[, .(from, to, type = relation, status)]
      e <- data.table::rbindlist(list(e_tr, e_cl, e_rl), use.names = TRUE)
      e <- e[, .(from, to, type, status)]
      e <- e[from %in% v$name & to %in% v$name]
      igraph::graph_from_data_frame(e, directed = TRUE, vertices = v)
    },

    #' @description Serialise the space to JSON (requires jsonlite).
    #' @param file Optional path; when given the JSON is written there.
    #' @param pretty Logical, indent the output.
    #' @return The JSON string, invisibly when `file` is given.
    to_json = function(file = NULL, pretty = TRUE) {
      if (!requireNamespace("jsonlite", quietly = TRUE)) {
        stop("Package 'jsonlite' is required for to_json().", call. = FALSE)
      }
      obj <- list(
        study = private$study,
        agents = self$agents(),
        findings = self$findings(),
        transformations = self$transformations(),
        claims = self$claims(),
        relations = self$relations(),
        decisions = self$decisions(),
        counts = as.list(self$counts())
      )
      js <- jsonlite::toJSON(
        obj,
        dataframe = "rows",
        auto_unbox = TRUE,
        pretty = pretty,
        na = "null",
        null = "null"
      )
      if (!is.null(file)) {
        writeLines(js, file, useBytes = TRUE)
        return(invisible(js))
      }
      js
    }
  ),

  private = list(
    study = NULL,
    strict = TRUE,
    tab = NULL,

    # 8. private helpers -----

    row_keys = function() {
      c(
        private$tab$findings$code,
        private$tab$claims$code,
        private$tab$relations$code,
        sprintf("T:%s", private$tab$transformations$new_finding)
      )
    },

    new_row_code = function(code, prefix) {
      used <- c(
        private$tab$findings$code,
        private$tab$claims$code,
        private$tab$relations$code
      )
      if (is.null(code)) {
        return(.next_code(prefix, used))
      }
      .check_scalar_string(code, "code")
      if (code %in% c(used, .reserved_rows) || startsWith(code, "T:")) {
        stop(
          "Code '",
          code,
          "' is already used or reserved; codes are ",
          "never reused.",
          call. = FALSE
        )
      }
      code
    },

    assert_agent = function(code, arg) {
      if (.is_blank(code) || !code %in% private$tab$agents$code) {
        stop(
          "`",
          arg,
          "` must be the code of a registered agent.",
          call. = FALSE
        )
      }
      invisible(code)
    },

    assert_can_endorse_at_creation = function(proposed_by, endorse) {
      if (is.null(endorse)) {
        return(invisible(TRUE))
      }
      ag <- private$tab$agents
      if (ag[code == proposed_by, type] != "person") {
        stop(
          "Rows proposed by a model or algorithm enter as candidates and ",
          "cannot be endorsed in the call that creates them; record a ",
          "separate decision with decide().",
          call. = FALSE
        )
      }
      if (.is_blank(endorse)) {
        stop("`endorse` must be the reason for the endorsement.", call. = FALSE)
      }
      invisible(TRUE)
    },

    endorse_at_creation = function(key, proposed_by, endorse, date) {
      if (is.null(endorse)) {
        return(invisible(NULL))
      }
      self$decide(
        key,
        "endorse",
        actor = proposed_by,
        reason = endorse,
        date = date
      )
    },

    status_table = function() {
      st <- private$latest_actions()
      tabs <- list(
        findings = private$tab$findings$code,
        transformations = sprintf("T:%s", private$tab$transformations$new_finding),
        claims = private$tab$claims$code,
        relations = private$tab$relations$code
      )
      out <- data.table::rbindlist(lapply(names(tabs), function(n) {
        data.table::data.table(
          table = rep(n, length(tabs[[n]])),
          row = tabs[[n]]
        )
      }))
      out[, status := private$status_of(row, st)]
      out
    },

    latest_actions = function() {
      dr <- private$tab$decision_rows
      dr[order(seq), .(action = action[.N]), by = row]
    },

    status_of = function(keys, latest = NULL) {
      if (is.null(latest)) {
        latest <- private$latest_actions()
      }
      a <- latest$action[match(keys, latest$row)]
      out <- rep("candidate", length(keys))
      out[a %in% "endorse"] <- "endorsed"
      out[a %in% "reject"] <- "rejected"
      out
    },

    filter_status = function(tbl, status) {
      if (is.null(status)) {
        return(tbl[])
      }
      bad <- setdiff(status, c("candidate", "endorsed", "rejected"))
      if (length(bad)) {
        stop(
          "Unknown status: ",
          paste(bad, collapse = ", "),
          ".",
          call. = FALSE
        )
      }
      keep <- tbl$status %in% status
      tbl[keep][]
    },

    # Endorsed findings (with strand) and endorsed transformations keyed by
    # output; when two endorsed transformations share an output, the later
    # row is used.
    root_context = function() {
      fs <- self$findings("endorsed")
      tr <- self$transformations("endorsed")
      tr <- tr[!duplicated(new_finding, fromLast = TRUE)]
      list(
        strand = stats::setNames(fs$strand, fs$code),
        made_from = stats::setNames(
          lapply(tr$made_from, .split_codes),
          tr$new_finding
        ),
        partition = stats::setNames(tr$partition, tr$new_finding)
      )
    },

    # Roots of one finding (workbook Check 1 with coding rule 12).
    finding_roots = function(f, ctx, seen = character()) {
      endorsed <- f %in% names(ctx$strand)
      if (f %in% names(ctx$made_from) && !f %in% seen) {
        out <- if (isTRUE(ctx$partition[[f]]) && endorsed) f else character()
        for (m in ctx$made_from[[f]]) {
          out <- union(out, private$finding_roots(m, ctx, c(seen, f)))
        }
        return(out)
      }
      if (endorsed) f else character()
    }
  )
)
