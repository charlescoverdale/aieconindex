#' Fetch the O*NET task statements bundled with a release
#'
#' Returns the table of O*NET task statements that the Anthropic Economic
#' Index uses as its task taxonomy.
#'
#' @details
#' The O*NET task statements file (`onet_task_statements.csv`) is
#' shipped alongside the 2025-03-27 release; later releases reference
#' O*NET through the enriched index file rather than redistributing
#' the statements separately. The default `release` argument is set
#' to `"2025-03-27"` for that reason. For later releases, the same
#' task identifiers can be joined back from
#' \code{aei_index(release, variant = "enriched")} where the
#' \code{cluster_name} column carries the O*NET task identifier when
#' \code{facet == "onet_task"}.
#'
#' @param release A release identifier. See [aei_files()].
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present.
#'
#' @references
#' U.S. Department of Labor, Employment and Training Administration.
#' O*NET Database. \url{https://www.onetonline.org/}
#'
#' Handa, K. et al. (2025). Which Economic Tasks are Performed with AI?
#' Evidence from Millions of Claude Conversations. arXiv:2503.04761.
#' \url{https://arxiv.org/abs/2503.04761}
#'
#' @return An [aei_tbl] containing the task statements.
#'
#' @family core data
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' aei_tasks("2025-03-27")
#' options(op)
#' }
aei_tasks <- function(release = "2025-03-27", use_cache = TRUE) {
  release_id <- .aei_resolve_release(release)
  files <- aei_files(release_id, recursive = TRUE)
  candidates <- files$path[files$type == "file" &
                           grepl("onet_task_statements\\.csv$", files$path)]
  if (length(candidates) == 0L) {
    cli::cli_abort(c(
      "No onet_task_statements.csv found in release {.val {release_id}}.",
      "i" = "The standalone task statements file ships in release_2025_03_27.",
      "i" = "For later releases, join from {.code aei_index(., variant = \"enriched\")} where {.field facet == \"onet_task\"}."
    ))
  }
  relpath <- sub(paste0("^", release_id, "/"), "", candidates[1L])
  path <- .aei_fetch_file(release_id, relpath, use_cache = use_cache)
  df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  new_aei_tbl(df, list(
    endpoint   = "tasks",
    release    = release_id,
    source_url = .aei_resolve_url(release_id, relpath),
    fetched_at = Sys.time()
  ))
}
