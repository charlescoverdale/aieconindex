#' Usage concentration metrics for an Anthropic Economic Index slice
#'
#' Computes Herfindahl-Hirschman Index (HHI), top-N concentration
#' ratios (CR4 by default), and Shannon entropy on a vector of usage
#' shares. Useful for asking "how concentrated is Claude usage across
#' tasks / occupations / countries?" against the same data the AEI
#' reports for percentage shares.
#'
#' @details
#' Three measures are produced for each call:
#'
#' \itemize{
#'   \item \strong{HHI} = sum of squared shares. Shares are used as
#'     supplied: percentages (0 to 100) give an HHI on the 0 to 10,000
#'     scale, proportions (0 to 1) give an HHI on the 0 to 1 scale.
#'   \item \strong{CR_n} = sum of the top-n shares. Defaults to CR4.
#'     Same units as the input.
#'   \item \strong{Entropy} = Shannon entropy in bits, computed on the
#'     normalised proportions (so it is invariant to the input scale).
#'     Maximum entropy at uniform distribution is `log2(n)` where `n`
#'     is the number of non-zero shares.
#' }
#'
#' When `x` is a filtered subset whose shares no longer total 100 (or
#' 1), the raw HHI and CR_n understate within-subset concentration.
#' Set `rescale = TRUE` to normalise shares to percentages summing to
#' 100 before computing HHI and CR_n; entropy is unaffected.
#'
#' Rows with `NA`, zero, or negative shares are dropped before
#' computation. If a `group_cols` argument is supplied, the metrics
#' are computed within each group.
#'
#' @param x A `data.frame` (or [aei_tbl]) with a column of shares.
#' @param share_col Character. Name of the share column. Defaults to
#'   `"value"` (the long-format AEI column name) if present, otherwise
#'   `"pct"`.
#' @param group_cols Optional character vector of grouping columns. If
#'   supplied, returns one row of metrics per group.
#' @param top_n Integer. The N for the CR_n top-share metric. Default 4.
#' @param rescale Logical. If `TRUE`, normalise the (positive) shares
#'   to percentages summing to 100 before computing HHI and CR_n, so
#'   the metrics measure concentration within the rows supplied.
#'   Default `FALSE` (use shares as supplied).
#'
#' @references
#' Hirschman, A. O. (1964). "The Paternity of an Index". \emph{The
#' American Economic Review}, 54(5), 761-762.
#'
#' Shannon, C. E. (1948). "A Mathematical Theory of Communication".
#' \emph{Bell System Technical Journal}, 27(3), 379-423.
#' \doi{10.1002/j.1538-7305.1948.tb01338.x}
#'
#' @return A `data.frame` with columns `n` (number of non-zero shares),
#'   `hhi`, `cr_n` (named after `top_n`, e.g. `cr_4`), `entropy_bits`,
#'   `entropy_max_bits` (= `log2(n)`), and `entropy_normalised`
#'   (`entropy_bits / entropy_max_bits`, on the unit interval). When
#'   `group_cols` is supplied, the grouping columns are prepended.
#'
#' @family analysis
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' uk <- aei_geography("2025-09-15", country = "GBR")
#' uk_tasks <- uk[uk$facet == "onet_task" & uk$variable == "onet_task_pct", ]
#' aei_concentration(uk_tasks)
#' options(op)
#' }
aei_concentration <- function(x,
                              share_col = NULL,
                              group_cols = NULL,
                              top_n = 4L,
                              rescale = FALSE) {
  if (!is.data.frame(x)) {
    cli::cli_abort("`x` must be a data.frame. Got {.cls {class(x)[1L]}}.")
  }
  if (is.null(share_col)) {
    share_col <- if ("value" %in% names(x)) "value"
                 else if ("pct" %in% names(x)) "pct"
                 else NULL
    if (is.null(share_col)) {
      cli::cli_abort(c(
        "Could not find a share column.",
        "i" = "Pass {.arg share_col} explicitly."
      ))
    }
  }
  if (!share_col %in% names(x)) {
    cli::cli_abort("Column {.val {share_col}} not found in {.field x}.")
  }
  if (!is.numeric(x[[share_col]])) {
    cli::cli_abort("Column {.val {share_col}} is not numeric.")
  }
  if (!is.null(group_cols)) {
    miss <- setdiff(group_cols, names(x))
    if (length(miss)) {
      cli::cli_abort("Group column(s) not found: {.val {miss}}")
    }
    g <- do.call(paste, c(x[group_cols], sep = ""))
    out <- do.call(rbind, lapply(split(x, g), function(sub) {
      r <- .aei_concentration_one(sub[[share_col]], top_n = top_n,
                                  rescale = rescale)
      cbind(sub[1L, group_cols, drop = FALSE], r)
    }))
    rownames(out) <- NULL
    return(out)
  }
  .aei_concentration_one(x[[share_col]], top_n = top_n, rescale = rescale)
}

.aei_concentration_one <- function(share, top_n = 4L, rescale = FALSE) {
  s <- share[!is.na(share) & share > 0]
  if (isTRUE(rescale) && length(s)) s <- s / sum(s) * 100
  if (length(s) == 0L) {
    out <- data.frame(n = 0L, hhi = NA_real_, entropy_bits = NA_real_,
                      entropy_max_bits = NA_real_,
                      entropy_normalised = NA_real_,
                      stringsAsFactors = FALSE)
    out[[paste0("cr_", top_n)]] <- NA_real_
    out <- out[, c("n", "hhi", paste0("cr_", top_n),
                   "entropy_bits", "entropy_max_bits", "entropy_normalised"),
               drop = FALSE]
    return(out)
  }
  s_sorted <- sort(s, decreasing = TRUE)
  cr <- sum(s_sorted[seq_len(min(top_n, length(s_sorted)))])
  hhi <- sum(s ^ 2)
  p <- s / sum(s)
  ent_bits <- -sum(p * log2(p))
  ent_max <- log2(length(s))
  ent_norm <- if (ent_max > 0) ent_bits / ent_max else NA_real_
  out <- data.frame(
    n                  = length(s),
    hhi                = hhi,
    entropy_bits       = ent_bits,
    entropy_max_bits   = ent_max,
    entropy_normalised = ent_norm,
    stringsAsFactors   = FALSE
  )
  out[[paste0("cr_", top_n)]] <- cr
  out[, c("n", "hhi", paste0("cr_", top_n),
          "entropy_bits", "entropy_max_bits", "entropy_normalised"),
      drop = FALSE]
}
