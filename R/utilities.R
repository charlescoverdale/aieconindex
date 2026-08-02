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
#   - report_url points to the Anthropic report (PDF or web report) for
#     that release when one exists; NA when the release is
#     documentation-only.
#
# Used as a fallback when the live Hugging Face API listing cannot be
# reached, and as the lookup for citation metadata in `aei_cite()`.
.aei_known_releases <- data.frame(
  release_id   = c("release_2025_02_10", "release_2025_03_27",
                   "release_2025_09_15", "release_2026_01_15",
                   "release_2026_03_24", "release_2026_06_26"),
  release_date = as.Date(c("2025-02-10", "2025-03-27",
                           "2025-09-15", "2026-01-15",
                           "2026-03-24", "2026-06-26")),
  model        = c("Claude 3.5 Sonnet", "Claude 3.7 Sonnet",
                   "Claude Sonnet 4", "Claude Sonnet 4.5",
                   "Claude Opus 4.5/4.6", "All Claude models"),
  report_url   = c("https://assets.anthropic.com/m/2e23255f1e84ca97/original/Economic_Tasks_AI_Paper.pdf",
                   "https://assets.anthropic.com/m/2e23255f1e84ca97/original/Economic_Tasks_AI_Paper.pdf",
                   "https://assets.anthropic.com/m/218c82b858610fac/original/Economic-Index.pdf",
                   "https://www-cdn.anthropic.com/096d94c1a91c6480806d8f24b2344c7e2a4bc666.pdf",
                   "https://www.anthropic.com/research/economic-index-march-2026-report",
                   "https://www.anthropic.com/research/economic-index-june-2026-report"),
  notes        = c("Initial release with O*NET task mappings and automation vs augmentation splits.",
                   "Cluster-level insights with the v2 report replication notebook.",
                   "Geographic and first-party API data added.",
                   "Economic primitives added.",
                   "Learning curves added.",
                   "Monthly cadence (April and May 2026 data); Artifacts metrics; new geo/category/metric schema; latest at package build."),
  stringsAsFactors = FALSE
)

# Parse the date embedded in a release_id ("release_2026_06_26" ->
# as.Date("2026-06-26")). Returns NA for ids without an embedded date
# (e.g. "labor_market_impacts").
.aei_release_id_date <- function(ids) {
  as.Date(sub("^release_", "", ids), format = "%Y_%m_%d")
}

# Classify a release into one of the three schema epochs the AEI has
# shipped so far. Date-based so that future releases default to the
# newest known schema rather than failing outright.
#   - "wide"    : up to 2025-03-27. One row per occupation/task, one
#                 column per measure. Variant-specific filenames.
#   - "long"    : 2025-09-15 to 2026-03-24. One row per
#                 geography-facet-variable combination, single `value`
#                 column. Filenames carry raw/enriched variants.
#   - "monthly" : 2026-06-26 onwards. Calendar-month aggregates with
#                 `geo_level`, `category_name`, `metric_id` columns and
#                 one file per source (no raw/enriched variant).
.aei_release_schema <- function(release_id) {
  d <- .aei_release_id_date(release_id)
  if (is.na(d)) return("unknown")
  if (d < as.Date("2025-09-15")) return("wide")
  if (d < as.Date("2026-06-26")) return("long")
  "monthly"
}

# Session-level memo of the live release directories on Hugging Face,
# so that release resolution costs at most one network round trip per
# session. Failures are not memoised, and offline use degrades to the
# bundled release list.
.aei_live_cache <- new.env(parent = emptyenv())

.aei_live_release_ids <- function() {
  if (!is.null(.aei_live_cache$ids)) return(.aei_live_cache$ids)
  listing <- tryCatch(.aei_hf_list(""), error = function(e) NULL)
  if (is.null(listing) || nrow(listing) == 0L) return(character(0L))
  ids <- listing$path[listing$type == "directory" &
                      grepl("^release_\\d{4}_\\d{2}_\\d{2}$", listing$path)]
  .aei_live_cache$ids <- ids
  ids
}

# Resolve a user-supplied release argument to a canonical release_id.
# Accepts:
#   - "latest"  : returns the most recent release_id by date, consulting
#                 the live Hugging Face listing so that releases published
#                 after this package version was built still resolve
#                 (offline use degrades to the bundled list)
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
    ids <- union(releases$release_id, .aei_live_release_ids())
    latest <- ids[which.max(.aei_release_id_date(ids))]
    if (!latest %in% releases$release_id) {
      cli::cli_inform(c(
        "Resolved {.val latest} to {.val {latest}}, published after this aieconindex version was built.",
        "i" = "Schema support may be partial; inspect with {.code aei_files({.val {latest}})}."
      ))
    }
    return(latest)
  }
  rel <- as.character(release)
  if (rel %in% releases$release_id) return(rel)
  candidate <- if (grepl("^release_", rel)) rel
               else paste0("release_", gsub("-", "_", rel))
  if (candidate %in% releases$release_id) return(candidate)
  d <- tryCatch(suppressWarnings(as.Date(rel)),
                error = function(e) as.Date(NA_character_))
  if (length(d) == 1L && !is.na(d) && d %in% releases$release_date) {
    return(releases$release_id[releases$release_date == d][1L])
  }
  # Releases published after this package version was built are not in
  # the bundled table; fall back to the live Hugging Face listing.
  live <- .aei_live_release_ids()
  if (candidate %in% live) return(candidate)
  if (length(d) == 1L && !is.na(d)) {
    hit <- live[!is.na(.aei_release_id_date(live)) & .aei_release_id_date(live) == d]
    if (length(hit)) return(hit[1L])
  }
  cli::cli_abort(c(
    "Could not resolve release {.val {release}}.",
    "i" = "Known releases: {.val {sort(union(releases$release_id, live), decreasing = TRUE)}}",
    "i" = "Use {.code aei_releases()} to see what is currently available on Hugging Face."
  ))
}

# Filename pattern for the canonical usage CSV of a release. The AEI
# dropped the raw/enriched variant from filenames with the monthly
# schema (release_2026_06_26 onwards): files are now named
# aei_<source>_<date>.csv rather than aei_<variant>_<source>_<dates>.csv.
.aei_index_pattern <- function(schema, variant, source) {
  if (identical(schema, "monthly")) {
    sprintf("aei_%s_\\d{4}-\\d{2}-\\d{2}.*\\.csv$", source)
  } else {
    sprintf("aei_%s_%s.*\\.csv$", variant, source)
  }
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
