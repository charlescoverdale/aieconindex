#' Compare two Anthropic Economic Index releases
#'
#' Side-by-side diff of the same metric across two releases. Useful
#' for tracking how the share of conversations classified to a given
#' O*NET task or country has shifted between two points in time.
#'
#' @details
#' The function fetches both releases via [aei_index()], inner-joins
#' them on the columns in `by`, and returns one row per shared key
#' with both values plus the absolute and percentage change. The
#' default join keys (`cluster_name`, `facet`, `variable`) are the
#' natural composite key of the long-format AEI schema introduced in
#' the 2025-09-15 release. For comparisons that include geographic
#' breakdowns add `geo_id` and `geography` to `by`.
#'
#' Releases that ship in different schemas (the wide-format 2025-02-10
#' and 2025-03-27 releases vs the long-format 2025-09-15+) cannot be
#' compared directly. Use [aei_download()] and a hand-written join in
#' that case.
#'
#' Pct-change is calculated as `(value_b - value_a) / value_a * 100`
#' and is `NA` where `value_a` is zero.
#'
#' @param release_a,release_b Release identifiers. See [aei_files()].
#'   `release_a` is treated as the baseline.
#' @param source Character. Either `"claude_ai"` or `"1p_api"`.
#' @param variant Character. Either `"raw"` or `"enriched"`.
#' @param by Character vector of join keys. Default is
#'   `c("cluster_name", "facet", "variable")` for the long-format
#'   schema. Add `c("geo_id", "geography")` to compare geography rows.
#' @param value_col Character. Name of the numeric column to compare.
#'   Default `"value"` for long-format AEI tables.
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
                        by = c("cluster_name", "facet", "variable"),
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
