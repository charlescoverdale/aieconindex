#' Fetch the request-hierarchy tree for a release
#'
#' The Anthropic Economic Index groups Claude requests into a multi-level
#' hierarchy of clusters using the Clio privacy-preserving system. From
#' the 2025-09-15 release onwards each release ships these trees as JSON
#' files. This function fetches the relevant tree as a parsed nested list.
#'
#' @details
#' Clusters are produced by the Clio system (Tamkin et al. 2024), which
#' summarises requests into facets, then groups them into a tree where
#' each level represents a coarser grouping. The JSON returned has one
#' entry per top-level cluster, each with `name`, optional
#' `description`, optional `count`, and a list of `children` mirroring
#' the same shape. Cluster summaries that fail Clio's privacy checks
#' (low cell counts, identifying information) are dropped before the
#' tree is published.
#'
#' Releases before 2025-09-15 do not contain request-hierarchy trees.
#'
#' @param release A release identifier. See [aei_files()].
#' @param source Character. Either `"claude_ai"` or `"1p_api"`.
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present.
#'
#' @references
#' Tamkin, A. et al. (2024). Clio: Privacy-Preserving Insights into
#' Real-World AI Use. arXiv:2412.13678.
#' \url{https://arxiv.org/abs/2412.13678}
#'
#' @return The parsed request hierarchy as a nested list.
#'
#' @family core data
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' tree <- aei_clusters("2025-09-15")
#' length(tree)
#' options(op)
#' }
aei_clusters <- function(release = "latest",
                         source = c("claude_ai", "1p_api"),
                         use_cache = TRUE) {
  source <- match.arg(source)
  release_id <- .aei_resolve_release(release)
  files <- aei_files(release_id, recursive = TRUE)
  pattern <- sprintf("request_hierarchy_tree_%s\\.json$", source)
  candidates <- files$path[files$type == "file" & grepl(pattern, files$path)]
  if (length(candidates) == 0L) {
    cli::cli_abort(c(
      "No request_hierarchy_tree_{source} JSON found in release {.val {release_id}}.",
      "i" = "Cluster trees were introduced in release_2025_09_15.",
      "i" = "Use {.code aei_files({.val {release_id}})} to inspect what is available."
    ))
  }
  relpath <- sub(paste0("^", release_id, "/"), "", candidates[1L])
  local <- .aei_fetch_file(release_id, relpath, use_cache = use_cache)
  jsonlite::fromJSON(local, simplifyVector = FALSE)
}
