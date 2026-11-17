#' interfacespace: Registers of Joint Qualitative-Quantitative Claims
#'
#' The package implements the interface space: the set of joint
#' qualitative-quantitative claims an evaluation produces, kept as a register
#' of findings, transformations, claims, relations among claims and
#' decisions with reasons. See [InterfaceSpace], [read_register()],
#' [register_counts()] and `vignette("interface-space")`.
#'
#' @keywords internal
#' @importFrom data.table := .SD .N
#' @importFrom R6 R6Class
#' @importFrom utils globalVariables
"_PACKAGE"

# 1. global variables used in data.table expressions -----

utils::globalVariables(c(
  "accepted",
  "decision",
  "proposed_by",
  "reversed",
  "table",
  "action",
  "claim",
  "code",
  "crosses_strand",
  "decision",
  "finding",
  "fit",
  "joint",
  "made_from",
  "new_finding",
  "partition",
  "reason",
  "related",
  "claims",
  "relation",
  "rests_on",
  "root",
  "row",
  "status",
  "strand",
  "type",
  "actor",
  "from",
  "to",
  "joint_codes",
  "related_share",
  "study"
))
