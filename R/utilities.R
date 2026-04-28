# Internal helpers shared across aieconindex.

# Hugging Face base URLs for the Anthropic Economic Index dataset.
.aei_dataset_id  <- "Anthropic/EconomicIndex"
.aei_api_base    <- "https://huggingface.co/api/datasets/Anthropic/EconomicIndex/tree/main"
.aei_resolve_base <- "https://huggingface.co/datasets/Anthropic/EconomicIndex/resolve/main"

# Releases known at package build time.
#
# Sources for each row:
#   - release_id and release_date come from the directory listing on
#     Hugging Face (https://huggingface.co/datasets/Anthropic/EconomicIndex).
#   - model is taken from each release's blog post on
#     https://www.anthropic.com/economic-index and the README inside the
#     release directory on Hugging Face.
#   - report_url points to the Anthropic report PDF for that release
#     when one exists; NA when the release is documentation-only.
#
# Used as a fallback when the live Hugging Face API listing cannot be
# reached, and as the lookup for citation metadata in `aei_cite()`.
.aei_known_releases <- data.frame(
  release_id   = c("release_2025_02_10", "release_2025_03_27",
                   "release_2025_09_15", "release_2026_01_15",
                   "release_2026_03_24"),
  release_date = as.Date(c("2025-02-10", "2025-03-27",
                           "2025-09-15", "2026-01-15",
                           "2026-03-24")),
  model        = c("Claude 3.5 Sonnet", "Claude 3.7 Sonnet",
                   "Claude Sonnet 4", "Claude Sonnet 4.5",
                   "Claude Opus 4.5/4.6"),
  report_url   = c("https://assets.anthropic.com/m/2e23255f1e84ca97/original/Economic_Tasks_AI_Paper.pdf",
                   "https://assets.anthropic.com/m/2e23255f1e84ca97/original/Economic_Tasks_AI_Paper.pdf",
                   "https://assets.anthropic.com/m/218c82b858610fac/original/Economic-Index.pdf",
                   "https://www-cdn.anthropic.com/096d94c1a91c6480806d8f24b2344c7e2a4bc666.pdf",
                   NA_character_),
  notes        = c("Initial release with O*NET task mappings and automation vs augmentation splits.",
                   "Cluster-level insights with the v2 report replication notebook.",
                   "Geographic and first-party API data added.",
                   "Economic primitives added.",
                   "Learning curves added; latest at package build."),
  stringsAsFactors = FALSE
)

# Resolve a user-supplied release argument to a canonical release_id.
# Accepts:
#   - "latest"  : returns the most recent release_id by date
#   - "2026_03_24" or "release_2026_03_24" : exact id (with or without prefix)
#   - a Date or coercible string ("2026-03-24")
.aei_resolve_release <- function(release, releases = NULL) {
  if (is.null(releases)) {
    releases <- .aei_known_releases
  }
  if (length(release) != 1L) {
    cli::cli_abort("`release` must be a single value, got length {length(release)}.")
  }
  if (identical(release, "latest")) {
    o <- order(releases$release_date, decreasing = TRUE)
    return(releases$release_id[o[1L]])
  }
  rel <- as.character(release)
  if (rel %in% releases$release_id) return(rel)
  candidate <- paste0("release_", sub("-", "_", sub("-", "_", rel)))
  if (candidate %in% releases$release_id) return(candidate)
  d <- tryCatch(suppressWarnings(as.Date(rel)),
                error = function(e) as.Date(NA_character_))
  if (length(d) == 1L && !is.na(d) && d %in% releases$release_date) {
    return(releases$release_id[releases$release_date == d][1L])
  }
  cli::cli_abort(c(
    "Could not resolve release {.val {release}}.",
    "i" = "Known releases: {.val {releases$release_id}}",
    "i" = "Use {.code aei_releases()} to see what is currently available on Hugging Face."
  ))
}

# Build a raw resolve URL for a given release + relative path.
.aei_resolve_url <- function(release_id, relpath) {
  paste(.aei_resolve_base, release_id, relpath, sep = "/")
}

# Format bytes as a human-readable string (B / KB / MB / GB / TB).
.aei_format_bytes <- function(x) {
  if (is.na(x)) return("NA")
  units <- c("B", "KB", "MB", "GB", "TB")
  i <- 1L
  while (x >= 1024 && i < length(units)) {
    x <- x / 1024
    i <- i + 1L
  }
  if (i == 1L) return(paste0(as.integer(x), " B"))
  sprintf("%.1f %s", x, units[i])
}

# Compose a short user-agent string for HTTP requests.
.aei_user_agent <- function() {
  ver <- tryCatch(as.character(utils::packageVersion("aieconindex")),
                  error = function(e) "0.0.0")
  paste0("aieconindex/", ver, " (https://github.com/charlescoverdale/aieconindex)")
}
