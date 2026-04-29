#' Join an Anthropic Economic Index table to your own data
#'
#' Generic merge helper that preserves the [aei_tbl] class and
#' provenance metadata. Use it to splice the AEI to any external data
#' frame on a shared key column, for example joining country-level
#' AEI shares to working-age employment counts from a national
#' labour-force survey, or joining O*NET task identifiers to a
#' user-supplied occupational crosswalk (SOC to ANZSCO, SOC to ISCO,
#' SOC to SOC2020 UK, etc.).
#'
#' @details
#' The function is a thin wrapper over [base::merge()] with two
#' differences. First, it preserves the `aei_tbl` class and the
#' `aei_query` provenance attribute on the returned object so that
#' downstream code can still see where the AEI side of the join came
#' from. Second, it warns when a join produces zero rows, which is
#' usually a sign of a key mismatch (typed differently, different
#' code system, or different case).
#'
#' For occupational crosswalks: the long-format AEI schema (from
#' 2025-09-15 onwards) carries the O*NET task identifier in the
#' `cluster_name` column when `facet == "onet_task"`, and SOC major
#' group codes appear in `cluster_name` when `facet == "onet_task"`
#' and `variable == "soc_pct"`. See `data_documentation.md` in each
#' release on Hugging Face for the authoritative schema.
#'
#' For country joins: country codes are ISO-3 in the enriched data
#' (`"GBR"`, `"AUS"`, `"USA"`). If your external data uses ISO-2 codes,
#' map them first with a small lookup table or with the
#' \pkg{countrycode} package on CRAN.
#'
#' @param x An [aei_tbl] returned by any data-fetching function.
#' @param y A `data.frame` (or `aei_tbl`) to join.
#' @param by Character vector of column names present in both `x` and
#'   `y`. Pass a named vector (e.g. `c(cluster_name = "onet_id")`) to
#'   join columns with different names.
#' @param type One of `"left"` (the default; keep all rows of `x`),
#'   `"inner"` (keep only matched rows), or `"full"` (keep all rows of
#'   both, fill with `NA`).
#' @param suffixes Character vector of length two giving suffixes to
#'   append to overlapping column names.
#'
#' @return An [aei_tbl] with the joined columns. Provenance metadata
#'   from `x` is preserved.
#'
#' @family analysis
#' @export
#' @examples
#' \donttest{
#' # Join AEI country shares to a small external table of GDP per capita
#' country <- aei_geography("2025-09-15")
#' overlay <- data.frame(
#'   geo_id = c("GBR", "AUS", "USA"),
#'   gdp_pc = c(48000, 65000, 80000)
#' )
#' joined <- aei_link(country, overlay, by = "geo_id")
#' head(joined)
#' }
aei_link <- function(x, y, by,
                     type = c("left", "inner", "full"),
                     suffixes = c(".aei", ".y")) {
  type <- match.arg(type)
  if (!inherits(x, "aei_tbl")) {
    cli::cli_abort("`x` must be an aei_tbl. Got {.cls {class(x)[1L]}}.")
  }
  if (!is.data.frame(y)) {
    cli::cli_abort("`y` must be a data.frame. Got {.cls {class(y)[1L]}}.")
  }
  if (missing(by) || length(by) == 0L) {
    cli::cli_abort("`by` must name at least one join column.")
  }
  by_x <- if (!is.null(names(by))) names(by) else by
  by_y <- if (!is.null(names(by))) unname(by) else by
  miss_x <- setdiff(by_x, names(x))
  miss_y <- setdiff(by_y, names(y))
  if (length(miss_x) || length(miss_y)) {
    cli::cli_abort(c(
      "Join columns not found.",
      "i" = "Missing in {.field x}: {.val {miss_x}}",
      "i" = "Missing in {.field y}: {.val {miss_y}}"
    ))
  }
  q <- attr(x, "aei_query")
  out <- merge(
    x, y,
    by.x = by_x, by.y = by_y,
    all.x = type %in% c("left", "full"),
    all.y = type %in% c("full"),
    all   = type == "full",
    suffixes = suffixes
  )
  if (nrow(out) == 0L) {
    cli::cli_warn(c(
      "Join produced zero rows.",
      "i" = "Check that key types and case match between x and y.",
      "i" = "AEI country codes are ISO-3 (GBR, AUS, USA) in enriched data."
    ))
  }
  rownames(out) <- NULL
  q$endpoint <- paste0(q$endpoint %||% "link", "+link")
  q$linked_cols <- setdiff(names(y), by_y)
  new_aei_tbl(out, q)
}
