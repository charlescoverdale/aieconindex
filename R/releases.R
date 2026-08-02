#' List available Anthropic Economic Index releases
#'
#' Queries the Hugging Face dataset listing for the Anthropic Economic
#' Index and returns one row per release, augmented with the headline
#' Claude model and a short note when the release is recognised. When
#' the network is unavailable (or `live = FALSE`), the function returns
#' the bundled list of releases known at package build time.
#'
#' @param live Logical. If `TRUE` (the default), query Hugging Face for
#'   the current set of release directories and merge with the bundled
#'   metadata. If `FALSE`, return the bundled list only.
#'
#' @return An [aei_tbl] with columns `release_id`, `release_date`,
#'   `model`, `report_url`, and `notes`.
#'
#' @family release discovery
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' aei_releases()
#' aei_releases(live = FALSE)
#' options(op)
#' }
aei_releases <- function(live = TRUE) {
  bundled <- .aei_known_releases
  out <- bundled
  source_url <- NA_character_
  if (isTRUE(live)) {
    listing <- tryCatch(
      .aei_hf_list(""),
      error = function(e) {
        cli::cli_warn(c(
          "Could not reach Hugging Face; returning bundled release list.",
          "i" = conditionMessage(e)
        ))
        NULL
      }
    )
    if (!is.null(listing) && nrow(listing) > 0L) {
      live_ids <- listing$path[listing$type == "directory" &
                               grepl("^release_\\d{4}_\\d{2}_\\d{2}$", listing$path)]
      if (length(live_ids)) {
        live_dates <- as.Date(sub("release_", "", live_ids), format = "%Y_%m_%d")
        live_df <- data.frame(release_id = live_ids,
                              release_date = live_dates,
                              stringsAsFactors = FALSE)
        merged <- merge(live_df, bundled, by = c("release_id", "release_date"),
                        all.x = TRUE, sort = FALSE)
        merged$model[is.na(merged$model)] <- "(unknown)"
        merged$notes[is.na(merged$notes)] <- "(metadata not bundled in this aieconindex version)"
        out <- merged[order(merged$release_date, decreasing = TRUE), , drop = FALSE]
        rownames(out) <- NULL
        source_url <- .aei_api_base
      }
    }
  }
  new_aei_tbl(out, list(
    endpoint   = "releases",
    source_url = source_url,
    fetched_at = Sys.time()
  ))
}

#' List files in an Anthropic Economic Index release
#'
#' Returns the file tree for a single release directory on Hugging Face,
#' descending into subdirectories. Useful for inspecting what raw files
#' are available before calling [aei_download()] or [aei_index()].
#'
#' @param release A release identifier. Either `"latest"`, a release id
#'   such as `"release_2026_03_24"`, or a date string `"2026-03-24"`.
#' @param recursive Logical. If `TRUE` (the default), recurse into
#'   subdirectories. If `FALSE`, list only the top level of the release.
#'
#' @return An [aei_tbl] with columns `path`, `type`, and `size_bytes`.
#'
#' @family release discovery
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' aei_files("2026-03-24", recursive = FALSE)
#' options(op)
#' }
aei_files <- function(release = "latest", recursive = TRUE) {
  release_id <- .aei_resolve_release(release)
  files <- .aei_hf_list(release_id)
  if (recursive && nrow(files) > 0L) {
    dirs <- files$path[files$type == "directory"]
    while (length(dirs)) {
      next_listing <- do.call(rbind, lapply(dirs, .aei_hf_list))
      files <- rbind(files, next_listing)
      dirs <- next_listing$path[next_listing$type == "directory"]
    }
  }
  out <- data.frame(
    path = files$path,
    type = files$type,
    size_bytes = files$size,
    stringsAsFactors = FALSE
  )
  out <- out[order(out$path), , drop = FALSE]
  rownames(out) <- NULL
  new_aei_tbl(out, list(
    endpoint   = "files",
    release    = release_id,
    source_url = paste0(.aei_api_base, "/", release_id),
    fetched_at = Sys.time()
  ))
}
