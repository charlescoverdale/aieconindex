# Local cache management for aieconindex.
#
# Cached files live under tools::R_user_dir("aieconindex", "cache"). The
# `aieconindex.cache_dir` option overrides this for testing.

#' Locate the aieconindex cache directory
#'
#' Returns the directory used to store downloaded AEI files. Defaults to
#' `tools::R_user_dir("aieconindex", "cache")`. Override by setting
#' `options(aieconindex.cache_dir = "/your/path")`.
#'
#' @return A character string giving the absolute path.
#' @export
aei_cache_dir <- function() {
  override <- getOption("aieconindex.cache_dir")
  if (!is.null(override) && nzchar(override)) return(normalizePath(override, mustWork = FALSE))
  tools::R_user_dir("aieconindex", "cache")
}

#' Clear the aieconindex cache
#'
#' Deletes all locally cached AEI files. The next call to any data
#' function will re-download from Hugging Face.
#'
#' @return Invisible `NULL`.
#' @family configuration
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' aei_cache_clear()
#' options(op)
#' }
aei_cache_clear <- function() {
  cdir <- aei_cache_dir()
  if (dir.exists(cdir)) {
    files <- list.files(cdir, full.names = TRUE, recursive = TRUE)
    if (length(files)) unlink(files, recursive = TRUE)
    cli::cli_inform("Cache cleared.")
  } else {
    cli::cli_inform("No cache to clear.")
  }
  invisible(NULL)
}

#' Inspect the local aieconindex cache
#'
#' Returns information about the local cache: where it lives, how many
#' files it contains, and how much disk space they take.
#'
#' @return A list with elements `dir`, `n_files`, `size_bytes`,
#'   `size_human`, and `files` (a data frame with `name`, `size_bytes`,
#'   and `modified` columns).
#' @family configuration
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' aei_cache_info()
#' options(op)
#' }
aei_cache_info <- function() {
  cdir <- aei_cache_dir()
  empty_files <- data.frame(
    name = character(0L),
    size_bytes = numeric(0L),
    modified = as.POSIXct(character(0L)),
    stringsAsFactors = FALSE
  )
  if (!dir.exists(cdir)) {
    return(list(dir = cdir, n_files = 0L, size_bytes = 0,
                size_human = "0 B", files = empty_files))
  }
  cdir_real <- normalizePath(cdir, mustWork = TRUE)
  paths <- list.files(cdir_real, full.names = TRUE, recursive = TRUE)
  if (length(paths) == 0L) {
    return(list(dir = cdir, n_files = 0L, size_bytes = 0,
                size_human = "0 B", files = empty_files))
  }
  info <- file.info(paths)
  files <- data.frame(
    name = sub(paste0("^", cdir_real, .Platform$file.sep), "", paths, fixed = TRUE),
    size_bytes = info$size,
    modified = info$mtime,
    stringsAsFactors = FALSE
  )
  files <- files[order(-files$size_bytes), , drop = FALSE]
  rownames(files) <- NULL
  total <- sum(files$size_bytes)
  list(dir = cdir, n_files = nrow(files), size_bytes = total,
       size_human = .aei_format_bytes(total), files = files)
}

# Construct the on-disk path where a release/file pair should be cached.
.aei_cache_path <- function(release_id, relpath) {
  cdir <- aei_cache_dir()
  out <- file.path(cdir, release_id, relpath)
  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  out
}
