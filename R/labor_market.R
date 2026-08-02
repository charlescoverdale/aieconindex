#' Fetch the AEI labor market impacts tables
#'
#' Alongside the dated releases, the Anthropic Economic Index publishes
#' a standalone `labor_market_impacts` directory on Hugging Face with
#' two tables from Anthropic's labor market research: occupation-level
#' job exposure and task-level penetration. This function fetches
#' either table. The directory keeps Anthropic's US spelling.
#'
#' @details
#' The two tables are:
#' \itemize{
#'   \item `"job_exposure"`: occupation-level exposure of jobs to AI
#'         usage, keyed on SOC occupation codes.
#'   \item `"task_penetration"`: task-level penetration of AI usage,
#'         keyed on O*NET task identifiers.
#' }
#' Unlike the dated releases, this directory is not versioned by date;
#' Anthropic may update it in place. Clear the cache with
#' [aei_cache_clear()] (or call with `use_cache = FALSE`) to force a
#' fresh download. See
#' \url{https://www.anthropic.com/research/labor-market-impacts} for
#' the accompanying research.
#'
#' @param table Character. Either `"job_exposure"` (the default) or
#'   `"task_penetration"`.
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present.
#'
#' @return An [aei_tbl] containing the requested table.
#'
#' @family core data
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' exposure <- aei_labor_market("job_exposure")
#' head(exposure)
#' options(op)
#' }
aei_labor_market <- function(table = c("job_exposure", "task_penetration"),
                             use_cache = TRUE) {
  table <- match.arg(table)
  relpath <- paste0(table, ".csv")
  path <- .aei_fetch_file("labor_market_impacts", relpath,
                          use_cache = use_cache)
  df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  new_aei_tbl(df, list(
    endpoint   = "labor_market",
    release    = "labor_market_impacts",
    facet      = table,
    source_url = .aei_resolve_url("labor_market_impacts", relpath),
    fetched_at = Sys.time()
  ))
}
