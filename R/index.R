#' Fetch the main usage table for an Anthropic Economic Index release
#'
#' Convenience wrapper that locates the canonical usage CSV for a
#' release and returns it as a tidy data frame. The shape and exact
#' filename of the canonical table varies across releases (the AEI
#' refactored its directory layout in late 2025); this function papers
#' over that variation by matching against well-known filename patterns.
#'
#' @details
#' File discovery uses the regular expression
#' `aei_<variant>_<source>.*\.csv$` against the recursive file listing
#' for a release. When more than one match exists (because a release
#' may ship multiple date windows or revisions), the matches are
#' sorted lexicographically descending and the first is used. Because
#' the AEI uses ISO dates in filenames (e.g. `_2026-02-05_to_2026-02-12`),
#' lexicographic sort approximates "most recent date window" but is
#' not guaranteed to be correct if Anthropic changes its filename
#' convention. Use [aei_files()] to inspect available files for a
#' release if the heuristic surprises you, then use [aei_download()]
#' to fetch a specific path.
#'
#' Schema differs across releases:
#' \itemize{
#'   \item Releases up to and including 2025-03-27 ship wide-format
#'         tables (one row per occupation/task, columns for shares).
#'   \item Releases from 2025-09-15 onward ship long-format tables
#'         (one row per geography-facet-variable combination, with
#'         a single `value` column).
#' }
#' See `data_documentation.md` in each release directory for the
#' authoritative schema.
#'
#' @param release A release identifier. See [aei_files()] for the list
#'   of valid forms.
#' @param source Character. Either `"claude_ai"` (Claude.ai consumer
#'   product traffic) or `"1p_api"` (first-party API traffic). Not all
#'   releases include both.
#' @param variant Character. Either `"raw"` (counts and percentages
#'   straight from Anthropic's pipeline) or `"enriched"` (joined to
#'   O*NET / SOC metadata, with derived per-capita and tier metrics).
#'   Older releases may only ship one variant.
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present. If `FALSE`, force a fresh download.
#'
#' @references
#' Handa, K. et al. (2025). Which Economic Tasks are Performed with AI?
#' Evidence from Millions of Claude Conversations. arXiv:2503.04761.
#' \url{https://arxiv.org/abs/2503.04761}
#'
#' @return An [aei_tbl] containing the usage table.
#'
#' @family core data
#' @export
#' @examples
#' \donttest{
#' aei_index("latest")
#' aei_index("2026-03-24", source = "1p_api")
#' aei_index("2025-09-15", variant = "enriched")
#' }
aei_index <- function(release = "latest",
                      source = c("claude_ai", "1p_api"),
                      variant = c("raw", "enriched"),
                      use_cache = TRUE) {
  source  <- match.arg(source)
  variant <- match.arg(variant)
  release_id <- .aei_resolve_release(release)
  files <- aei_files(release_id, recursive = TRUE)
  pattern <- sprintf("aei_%s_%s.*\\.csv$", variant, source)
  candidates <- files$path[files$type == "file" & grepl(pattern, files$path)]
  if (length(candidates) == 0L) {
    cli::cli_abort(c(
      "No {.field {variant}}/{.field {source}} CSV found in release {.val {release_id}}.",
      "i" = "Use {.code aei_files({.val {release_id}})} to inspect what is available.",
      "i" = "Older releases sometimes only ship one variant or one source."
    ))
  }
  if (length(candidates) > 1L) {
    candidates <- candidates[order(candidates, decreasing = TRUE)]
    cli::cli_inform("Multiple matches found; using {.path {candidates[1L]}}.")
  }
  relpath <- sub(paste0("^", release_id, "/"), "", candidates[1L])
  path <- .aei_fetch_file(release_id, relpath, use_cache = use_cache)
  df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  new_aei_tbl(df, list(
    endpoint   = "index",
    release    = release_id,
    facet      = paste(variant, source, sep = "/"),
    source_url = .aei_resolve_url(release_id, relpath),
    fetched_at = Sys.time()
  ))
}

#' Download an arbitrary file from an Anthropic Economic Index release
#'
#' Lower-level fetcher than [aei_index()]. Pass any path returned by
#' [aei_files()] and get the file back as a parsed data frame (CSV) or
#' list (JSON), or as a local path if the file extension is unrecognised.
#'
#' @details
#' CSV files are read with `utils::read.csv(stringsAsFactors = FALSE,
#' check.names = FALSE)`, which preserves the original column names
#' verbatim (the AEI uses dots and double colons in some column names
#' that R would otherwise mangle). JSON files are parsed with
#' `jsonlite::fromJSON(simplifyVector = FALSE)` to preserve the nested
#' tree structure of the request hierarchies. For other extensions
#' (e.g. PDF reports, PNG figures, IPython notebooks) the function
#' returns the local cached path so that the caller can do whatever
#' they like with the file.
#'
#' @param release A release identifier. See [aei_files()].
#' @param path Character. A relative path within the release directory,
#'   for example `"data/aei_raw_claude_ai_2026-02-05_to_2026-02-12.csv"`.
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present.
#'
#' @return For CSV files, an [aei_tbl]. For JSON files, the parsed
#'   list. For other extensions, the absolute local path of the cached
#'   file.
#'
#' @family core data
#' @export
#' @examples
#' \donttest{
#' aei_download("2025-03-27", "task_pct_v2.csv")
#' aei_download("2025-09-15", "data/output/request_hierarchy_tree_claude_ai.json")
#' }
aei_download <- function(release, path, use_cache = TRUE) {
  release_id <- .aei_resolve_release(release)
  local <- .aei_fetch_file(release_id, path, use_cache = use_cache)
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    df <- utils::read.csv(local, stringsAsFactors = FALSE, check.names = FALSE)
    return(new_aei_tbl(df, list(
      endpoint   = "download",
      release    = release_id,
      source_url = .aei_resolve_url(release_id, path),
      fetched_at = Sys.time()
    )))
  }
  if (ext == "json") {
    return(jsonlite::fromJSON(local, simplifyVector = FALSE))
  }
  local
}
