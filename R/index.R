#' Fetch the main usage table for an Anthropic Economic Index release
#'
#' Convenience wrapper that locates the canonical usage CSV for a
#' release and returns it as a tidy data frame. The shape and exact
#' filename of the canonical table varies across releases (the AEI
#' refactored its directory layout in late 2025); this function papers
#' over that variation by matching against well-known filename patterns.
#'
#' @details
#' File discovery matches well-known filename patterns against the
#' recursive file listing for a release: releases up to 2026-03-24 use
#' `aei_<variant>_<source>.*\.csv$`, and releases from 2026-06-26
#' onwards use `aei_<source>_<date>.csv` (the raw/enriched variant was
#' dropped from filenames with the monthly schema). When more than one
#' match exists (because a release may ship multiple date windows or
#' revisions), the matches are sorted lexicographically descending and
#' the first is used. Because the AEI uses ISO dates in filenames,
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
#'   \item Releases from 2025-09-15 to 2026-03-24 ship long-format
#'         tables (one row per geography-facet-variable combination,
#'         with a single `value` column).
#'   \item Releases from 2026-06-26 onwards ship calendar-month
#'         aggregates (one row per date window, geography, category,
#'         and metric, with `geo_level`, `category_name`,
#'         `hierarchy_level`, `metric_id`, `node_name`, and `value`
#'         columns). These releases ship a single file per source, so
#'         the `variant` argument is ignored. A release can contain
#'         more than one calendar month; filter on `date_start` if you
#'         need a single window.
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
#'   Older releases may only ship one variant. Ignored for releases
#'   from 2026-06-26 onwards, which ship a single file per source.
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
#' op <- options(aieconindex.cache_dir = tempdir())
#' aei_index("2025-09-15", variant = "enriched")
#' options(op)
#' }
aei_index <- function(release = "latest",
                      source = c("claude_ai", "1p_api"),
                      variant = c("raw", "enriched"),
                      use_cache = TRUE) {
  source  <- match.arg(source)
  variant <- match.arg(variant)
  release_id <- .aei_resolve_release(release)
  schema <- .aei_release_schema(release_id)
  files <- aei_files(release_id, recursive = TRUE)
  pattern <- .aei_index_pattern(schema, variant, source)
  candidates <- files$path[files$type == "file" & grepl(pattern, files$path)]
  if (length(candidates) == 0L) {
    # The schema epochs are date-derived; if a release breaks the
    # convention for its epoch, try the other epoch's pattern before
    # giving up.
    alt <- .aei_index_pattern(if (schema == "monthly") "long" else "monthly",
                              variant, source)
    candidates <- files$path[files$type == "file" & grepl(alt, files$path)]
  }
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
  dest <- .aei_cache_path(release_id, relpath)
  size <- files$size_bytes[match(candidates[1L], files$path)]
  if (!is.na(size) && size > 50 * 1024^2 &&
      !(use_cache && file.exists(dest) && file.info(dest)$size > 0)) {
    size_human <- .aei_format_bytes(size)
    cli::cli_inform("This file is {size_human}; the download may take a while and will be cached for reuse.")
  }
  path <- .aei_fetch_file(release_id, relpath, use_cache = use_cache)
  df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  new_aei_tbl(df, list(
    endpoint   = "index",
    release    = release_id,
    facet      = if (schema == "monthly") source else paste(variant, source, sep = "/"),
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
#' op <- options(aieconindex.cache_dir = tempdir())
#' aei_download("2025-03-27", "task_pct_v2.csv")
#' options(op)
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
