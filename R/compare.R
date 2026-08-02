#' Compare two Anthropic Economic Index releases
#'
#' Side-by-side diff of the same metric across two releases. Useful
#' for tracking how the share of conversations classified to a given
#' O*NET task or country has shifted between two points in time.
#'
#' @details
#' The function fetches both releases via [aei_index()], inner-joins
#' them on the columns in `by`, and returns one row per shared key
#' with both values plus the absolute and percentage change. When `by`
#' is `NULL` (the default) the join keys are chosen from the columns
#' the two tables share: `c("cluster_name", "facet", "variable")` for
#' the long-format schema (2025-09-15 to 2026-03-24), or
#' `c("geo_id", "geo_level", "category_name", "hierarchy_level",
#' "metric_id", "node_name")` for the monthly schema (2026-06-26
#' onwards). For long-format comparisons that include geographic
#' breakdowns add `geo_id` and `geography` to `by`.
#'
#' Monthly-schema releases can contain more than one calendar month.
#' Before joining, each side is filtered to its most recent
#' `date_start` window so that keys stay unique; a message reports the
#' window used.
#'
#' Releases that ship in different schemas cannot be compared
#' directly. Use [aei_download()] and a hand-written join in that
#' case.
#'
#' Pct-change is calculated as `(value_b - value_a) / value_a * 100`
#' and is `NA` where `value_a` is zero.
#'
#' @param release_a,release_b Release identifiers. See [aei_files()].
#'   `release_a` is treated as the baseline.
#' @param source Character. Either `"claude_ai"` or `"1p_api"`.
#' @param variant Character. Either `"raw"` or `"enriched"`. Ignored
#'   for monthly-schema releases (2026-06-26 onwards).
#' @param by Character vector of join keys, or `NULL` (the default) to
#'   choose them automatically from the schema both releases share.
#' @param value_col Character. Name of the numeric column to compare.
#'   Default `"value"`.
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present.
#'
#' @references
#' Handa, K. et al. (2025). Which Economic Tasks are Performed with AI?
#' Evidence from Millions of Claude Conversations. arXiv:2503.04761.
#' \url{https://arxiv.org/abs/2503.04761}
#'
#' @return An [aei_tbl] with the join keys plus `value_a`, `value_b`,
#'   `delta` (= `value_b - value_a`), and `pct_change`.
#'
#' @family analysis
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' diff <- aei_compare("2025-09-15", "2026-03-24")
#' head(diff[order(-abs(diff$delta)), ])
#' options(op)
#' }
aei_compare <- function(release_a, release_b,
                        source = c("claude_ai", "1p_api"),
                        variant = c("raw", "enriched"),
                        by = NULL,
                        value_col = "value",
                        use_cache = TRUE) {
  source  <- match.arg(source)
  variant <- match.arg(variant)
  release_a_id <- .aei_resolve_release(release_a)
  release_b_id <- .aei_resolve_release(release_b)
  if (identical(release_a_id, release_b_id)) {
    cli::cli_abort("Cannot compare a release with itself ({.val {release_a_id}}).")
  }
  a <- aei_index(release_a_id, source = source, variant = variant, use_cache = use_cache)
  b <- aei_index(release_b_id, source = source, variant = variant, use_cache = use_cache)
  a <- .aei_latest_window(a, release_a_id)
  b <- .aei_latest_window(b, release_b_id)
  if (is.null(by)) {
    by <- .aei_compare_by(names(a), names(b))
  }
  missing_a <- setdiff(c(by, value_col), names(a))
  missing_b <- setdiff(c(by, value_col), names(b))
  if (length(missing_a) || length(missing_b)) {
    cli::cli_abort(c(
      "Join keys not present in both releases.",
      "i" = "Missing in {.val {release_a_id}}: {.val {missing_a}}",
      "i" = "Missing in {.val {release_b_id}}: {.val {missing_b}}",
      "i" = "Wide-format and long-format releases cannot be compared directly."
    ))
  }
  a_sub <- a[, c(by, value_col), drop = FALSE]
  b_sub <- b[, c(by, value_col), drop = FALSE]
  names(a_sub)[length(by) + 1L] <- "value_a"
  names(b_sub)[length(by) + 1L] <- "value_b"
  out <- merge(a_sub, b_sub, by = by, all = FALSE)
  out$delta <- out$value_b - out$value_a
  out$pct_change <- ifelse(out$value_a == 0, NA_real_,
                           (out$value_b - out$value_a) / out$value_a * 100)
  rownames(out) <- NULL
  new_aei_tbl(out, list(
    endpoint   = "compare",
    release    = paste(release_a_id, release_b_id, sep = " vs "),
    facet      = paste(variant, source, sep = "/"),
    fetched_at = Sys.time()
  ))
}

# Pick default join keys from the columns both releases share. The two
# candidate sets are the natural composite keys of the long-format and
# monthly AEI schemas.
.aei_compare_by <- function(names_a, names_b) {
  monthly <- c("geo_id", "geo_level", "category_name",
               "hierarchy_level", "metric_id", "node_name")
  long <- c("cluster_name", "facet", "variable")
  if (all(monthly %in% names_a) && all(monthly %in% names_b)) return(monthly)
  if (all(long %in% names_a) && all(long %in% names_b)) return(long)
  cli::cli_abort(c(
    "Could not choose default join keys for these releases.",
    "i" = "The releases may use different schemas, which cannot be compared directly.",
    "i" = "Pass {.arg by} explicitly, or use {.fn aei_download} and a hand-written join."
  ))
}

# Monthly-schema releases ship more than one calendar month in a single
# file. Reduce to the most recent date window so that the composite key
# is unique before joining.
.aei_latest_window <- function(x, release_id = "?") {
  if (!"date_start" %in% names(x)) return(x)
  ds <- as.character(x$date_start)
  latest <- max(ds, na.rm = TRUE)
  if (!all(ds == latest, na.rm = TRUE)) {
    cli::cli_inform("Release {.val {release_id}} ships multiple date windows; using {.val {latest}}.")
    x <- x[!is.na(ds) & ds == latest, , drop = FALSE]
  }
  x
}
