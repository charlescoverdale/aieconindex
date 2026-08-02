#' Filter the usage table to country or subregion rows
#'
#' From the 2025-09-15 release onward the Anthropic Economic Index
#' ships geographic breakdowns as rows of its main usage table. This
#' function fetches that table via [aei_index()] and filters it to the
#' requested geographic level, optionally to a single country.
#'
#' @details
#' Two geographic schemas exist:
#' \itemize{
#'   \item Releases from 2025-09-15 to 2026-03-24 (long format) carry a
#'         `geography` column with values `"country"`, `"state_us"`,
#'         and `"global"`, plus a `geo_id` column holding ISO-3 country
#'         codes or US state codes.
#'   \item Releases from 2026-06-26 onwards (monthly format) carry a
#'         `geo_level` column with values `"country"`, `"subregion"`,
#'         and `"global"`, plus a `geo_id` column holding ISO 3166-1
#'         alpha-3 country codes or ISO 3166-2 subregion codes (US
#'         states appear as `"US-CA"`, `"US-NY"`, and so on).
#' }
#' The `geography` argument is mapped onto whichever schema the release
#' uses: `"country"` selects country rows in both; `"state_us"` selects
#' `state_us` rows in the long schema and US subregion rows (`geo_id`
#' starting `"US-"`) in the monthly schema; `"subregion"` selects all
#' subregion rows and is only available from 2026-06-26 onwards.
#'
#' Releases before 2025-09-15 do not contain geographic data; calling
#' `aei_geography()` on them returns an informative error.
#'
#' @param release A release identifier. See [aei_files()]. Defaults to
#'   `"latest"`.
#' @param source Character. Either `"claude_ai"` or `"1p_api"`. The 1P
#'   API data ships only `"global"` rows, so country filtering will
#'   typically return nothing for that source.
#' @param geography Character. One of `"country"`, `"state_us"`, or
#'   `"subregion"`.
#' @param country Optional ISO 3166-1 alpha-3 country code (for
#'   example `"GBR"`, `"AUS"`, `"USA"`). If `NULL` (the default), all
#'   rows at the requested level are returned.
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present.
#'
#' @references
#' Handa, K. et al. (2025). Which Economic Tasks are Performed with AI?
#' Evidence from Millions of Claude Conversations. arXiv:2503.04761.
#' \url{https://arxiv.org/abs/2503.04761}
#'
#' @return An [aei_tbl] containing the geographic rows of the usage
#'   table.
#'
#' @family core data
#' @export
#' @examples
#' \donttest{
#' op <- options(aieconindex.cache_dir = tempdir())
#' uk <- aei_geography("2025-09-15", country = "GBR")
#' head(uk)
#' options(op)
#' }
aei_geography <- function(release = "latest",
                          source = c("claude_ai", "1p_api"),
                          geography = c("country", "state_us", "subregion"),
                          country = NULL,
                          use_cache = TRUE) {
  source    <- match.arg(source)
  geography <- match.arg(geography)
  release_id <- .aei_resolve_release(release)
  if (identical(.aei_release_schema(release_id), "wide")) {
    cli::cli_abort(c(
      "Release {.val {release_id}} does not contain geographic data.",
      "i" = "Geographic facets were introduced in release_2025_09_15.",
      "i" = "Use {.code aei_geography({.val \"2025-09-15\"})} or later."
    ))
  }
  enriched <- aei_index(release_id, source = source,
                        variant = "enriched", use_cache = use_cache)
  out <- .aei_geography_filter(enriched, geography, country, release_id)
  rownames(out) <- NULL
  new_aei_tbl(out, list(
    endpoint   = "geography",
    release    = release_id,
    facet      = paste(source, geography, sep = "/"),
    country    = country,
    source_url = attr(enriched, "aei_query")$source_url,
    fetched_at = Sys.time()
  ))
}

# Filter a usage table to the requested geographic level, dispatching
# on whichever geographic schema the table carries. Split out from
# aei_geography() so the logic can be unit-tested without downloading
# the (large) usage tables.
.aei_geography_filter <- function(df, geography, country, release_id = "?") {
  if ("geo_level" %in% names(df)) {
    # Monthly schema (2026-06-26 onwards): geo_level + ISO 3166-2
    # subregion codes.
    keep <- switch(geography,
      country   = df$geo_level == "country",
      state_us  = df$geo_level == "subregion" &
                    grepl("^US-", as.character(df$geo_id)),
      subregion = df$geo_level == "subregion"
    )
    out <- df[keep, , drop = FALSE]
  } else if ("geography" %in% names(df)) {
    # Long schema (2025-09-15 to 2026-03-24): geography column with
    # country / state_us / global.
    if (identical(geography, "subregion")) {
      cli::cli_abort(c(
        "Release {.val {release_id}} predates the {.val subregion} level.",
        "i" = "Subregion rows ship from release_2026_06_26 onwards.",
        "i" = "Use {.code geography = \"state_us\"} for the US-state breakdown."
      ))
    }
    out <- df[df$geography == geography, , drop = FALSE]
  } else {
    cli::cli_abort(c(
      "The table for release {.val {release_id}} has no {.field geography} or {.field geo_level} column.",
      "i" = "The schema may have changed; use {.code aei_files({.val {release_id}})} to inspect."
    ))
  }
  if (!is.null(country)) {
    if (!"geo_id" %in% names(out)) {
      cli::cli_warn("No `geo_id` column to filter on; returning all rows for geography = {.val {geography}}.")
    } else {
      keep <- toupper(as.character(out$geo_id)) == toupper(country)
      out <- out[keep, , drop = FALSE]
    }
  }
  out
}
