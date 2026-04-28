# HTTP layer for fetching files from the Hugging Face mirror of the
# Anthropic Economic Index. No API key is required; everything is public.

# Fetch a Hugging Face directory listing. Returns a data frame with
# columns `type` ("file" or "directory"), `path`, and `size`.
.aei_hf_list <- function(subpath = "") {
  url <- if (nzchar(subpath)) paste0(.aei_api_base, "/", subpath) else .aei_api_base
  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, .aei_user_agent())
  req <- httr2::req_retry(
    req, max_tries = 3L,
    is_transient = function(resp) httr2::resp_status(resp) %in% c(429L, 500L, 502L, 503L, 504L),
    backoff = ~ 2
  )
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to reach the Hugging Face dataset listing at {.url {url}}.",
        "i" = "Check your internet connection or try again later.",
        "i" = "Original error: {conditionMessage(e)}"
      ))
    }
  )
  status <- httr2::resp_status(resp)
  if (status == 404L) {
    cli::cli_abort(c(
      "Hugging Face returned 404 for {.url {url}}.",
      "i" = "The dataset path may have changed or the release does not exist."
    ))
  }
  if (status >= 400L) {
    cli::cli_abort("Hugging Face returned HTTP {status} for {.url {url}}.")
  }
  body <- httr2::resp_body_json(resp)
  if (length(body) == 0L) {
    return(data.frame(type = character(), path = character(),
                      size = numeric(), stringsAsFactors = FALSE))
  }
  df <- data.frame(
    type = vapply(body, function(x) x$type %||% NA_character_, character(1L)),
    path = vapply(body, function(x) x$path %||% NA_character_, character(1L)),
    size = vapply(body,
                  function(x) {
                    s <- x$size
                    if (is.null(s)) NA_real_ else as.numeric(s)
                  }, numeric(1L)),
    stringsAsFactors = FALSE
  )
  df
}

# Fetch a raw file from Hugging Face into the cache and return the local
# path. If the file is already cached, the cached copy is returned and
# no network call is made.
.aei_fetch_file <- function(release_id, relpath, use_cache = TRUE,
                            quiet = FALSE) {
  dest <- .aei_cache_path(release_id, relpath)
  if (use_cache && file.exists(dest) && file.info(dest)$size > 0) {
    return(dest)
  }
  url <- .aei_resolve_url(release_id, relpath)
  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, .aei_user_agent())
  req <- httr2::req_retry(
    req, max_tries = 3L,
    is_transient = function(resp) httr2::resp_status(resp) %in% c(429L, 500L, 502L, 503L, 504L),
    backoff = ~ 2
  )
  if (!quiet) cli::cli_inform("Downloading {.url {url}}")
  resp <- tryCatch(
    httr2::req_perform(req, path = dest),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to download {.url {url}}.",
        "i" = "Original error: {conditionMessage(e)}"
      ))
    }
  )
  status <- httr2::resp_status(resp)
  if (status == 404L) {
    if (file.exists(dest)) unlink(dest)
    cli::cli_abort(c(
      "File not found on Hugging Face: {.path {relpath}} in release {.val {release_id}}.",
      "i" = "Use {.code aei_releases()} or check the dataset on Hugging Face."
    ))
  }
  if (status >= 400L) {
    if (file.exists(dest)) unlink(dest)
    cli::cli_abort("Hugging Face returned HTTP {status} for {.url {url}}.")
  }
  dest
}

# Null-coalescing operator (avoids depending on rlang).
`%||%` <- function(a, b) if (is.null(a)) b else a
