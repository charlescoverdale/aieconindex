#' Filter the enriched usage table to country or US-state rows
#'
#' From the 2025-09-15 release onward the Anthropic Economic Index
#' ships a single long-format enriched CSV with one row per
#' geography-facet-variable combination. Geographic breakdowns are
#' rows in that table where the `geography` column is `"country"` or
#' `"state_us"`. This function fetches the enriched table via
#' [aei_index()] with `variant = "enriched"` and filters those rows.
#'
#' @details
#' The enriched table has columns `geo_id` (ISO-3 country code or US
#' state code after enrichment), `geography` (one of `"country"`,
#' `"state_us"`, `"global"`), `facet`, `variable`, `cluster_name`, and
#' `value`. Setting `country = "GBR"` or `country = "AUS"` filters to
#' that single country; the codes are ISO-3 in the enriched data.
#' Setting `geography = "state_us"` returns the US-state breakdown
#' instead of the country breakdown.
#'
#' Releases before 2025-09-15 do not contain geographic data; calling
#' `aei_geography()` on them returns an informative error.
#'
#' @param release A release identifier. See [aei_files()].
#' @param source Character. Either `"claude_ai"` or `"1p_api"`. The 1P
#'   API release ships only `"global"` rows, so country filtering will
#'   typically return nothing for that source.
#' @param geography Character. Either `"country"` or `"state_us"`.
#' @param country Optional ISO 3166-1 alpha-3 country code in the
#'   enriched data (for example `"GBR"`, `"AUS"`, `"USA"`). If `NULL`
#'   (the default), all countries are returned.
#' @param use_cache Logical. If `TRUE` (the default), use the local
#'   cache when present.
#'
#' @references
#' Handa, K. et al. (2025). Which Economic Tasks are Performed with AI?
#' Evidence from Millions of Claude Conversations. arXiv:2503.04761.
#' \url{https://arxiv.org/abs/2503.04761}
#'
#' @return An [aei_tbl] containing the long-format geographic rows of
#'   the enriched usage table.
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
aei_geography <- function(release = "2025-09-15",
                          source = c("claude_ai", "1p_api"),
                          geography = c("country", "state_us"),
                          country = NULL,
                          use_cache = TRUE) {
  source    <- match.arg(source)
  geography <- match.arg(geography)
  release_id <- .aei_resolve_release(release)
  if (release_id %in% c("release_2025_02_10", "release_2025_03_27")) {
    cli::cli_abort(c(
      "Release {.val {release_id}} does not contain geographic data.",
      "i" = "Geographic facets were introduced in release_2025_09_15.",
      "i" = "Use {.code aei_geography({.val \"2025-09-15\"})} or later."
    ))
  }
  enriched <- aei_index(release_id, source = source,
                        variant = "enriched", use_cache = use_cache)
  if (!"geography" %in% names(enriched)) {
    cli::cli_abort(c(
      "The enriched table for release {.val {release_id}} has no {.field geography} column.",
      "i" = "The schema may have changed; use {.code aei_files({.val {release_id}})} to inspect."
    ))
  }
  out <- enriched[enriched$geography == geography, , drop = FALSE]
  if (!is.null(country)) {
    if (!"geo_id" %in% names(out)) {
      cli::cli_warn("No `geo_id` column to filter on; returning all rows for geography = {.val {geography}}.")
    } else {
      keep <- toupper(as.character(out$geo_id)) == toupper(country)
      out <- out[keep, , drop = FALSE]
    }
  }
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
