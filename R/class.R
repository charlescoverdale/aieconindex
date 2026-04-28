# S3 class for Anthropic Economic Index query results.

#' The aei_tbl class
#'
#' An `aei_tbl` is a `data.frame` returned by all data-fetching
#' functions in this package. It carries provenance metadata as the
#' `aei_query` attribute, and dispatches a custom [print()],
#' [summary()], and `[` method that preserves the metadata when the
#' table is subset.
#'
#' Inspect the metadata directly with `attr(x, "aei_query")`.
#'
#' @name aei_tbl
#' @aliases aei_tbl-class
#' @return An object of class `aei_tbl`, which inherits from `data.frame`.
#' @examples
#' df <- data.frame(a = 1:3)
#' attr(df, "aei_query") <- list(endpoint = "demo", release = "rel")
#' class(df) <- c("aei_tbl", "data.frame")
#' print(df)
NULL

#' Construct an aei_tbl
#'
#' @param df A data frame.
#' @param query A list of query metadata stored as the `aei_query` attribute.
#' @return An `aei_tbl` (subclass of `data.frame`).
#' @noRd
new_aei_tbl <- function(df, query = list()) {
  if (!is.data.frame(df)) {
    df <- as.data.frame(df, stringsAsFactors = FALSE)
  }
  attr(df, "aei_query") <- query
  class(df) <- c("aei_tbl", "data.frame")
  df
}

#' Print method for aei_tbl
#'
#' Prepends a one-line provenance header summarising the query.
#'
#' @param x An `aei_tbl`.
#' @param ... Passed to the underlying `print.data.frame` method.
#' @return `x`, invisibly.
#' @export
print.aei_tbl <- function(x, ...) {
  cat(sprintf("# AEI: %s\n", .aei_tbl_header(x)))
  NextMethod()
}

#' Summary method for aei_tbl
#'
#' @param object An `aei_tbl`.
#' @param ... Passed to the underlying `summary.data.frame` method.
#' @return Invisibly returns the standard data frame summary.
#' @export
summary.aei_tbl <- function(object, ...) {
  q <- attr(object, "aei_query")
  cat(sprintf("AEI query summary: %s\n", .aei_tbl_header(object)))
  cat(sprintf("  rows: %d  cols: %d\n", nrow(object), ncol(object)))
  if (!is.null(q$release))  cat(sprintf("  release: %s\n", q$release))
  if (!is.null(q$facet))    cat(sprintf("  facet: %s\n", q$facet))
  if (!is.null(q$source_url)) cat(sprintf("  source: %s\n", q$source_url))
  if (!is.null(q$fetched_at)) cat(sprintf("  fetched_at: %s\n",
                                          format(q$fetched_at, "%Y-%m-%d %H:%M:%S %Z")))
  cat("\n")
  invisible(NextMethod())
}

#' Subset method for aei_tbl
#'
#' Preserves the `aei_tbl` class and `aei_query` attribute when subsetting.
#'
#' @param x An `aei_tbl`.
#' @param i Row selector.
#' @param j Column selector.
#' @param ... Other arguments passed to `[.data.frame`.
#' @param drop Logical. As in `[.data.frame`.
#' @return An `aei_tbl` (or a vector if `drop` collapses the result).
#' @export
`[.aei_tbl` <- function(x, i, j, ..., drop = TRUE) {
  q <- attr(x, "aei_query")
  out <- NextMethod()
  if (is.data.frame(out)) {
    attr(out, "aei_query") <- q
    class(out) <- c("aei_tbl", "data.frame")
  }
  out
}

# Build the one-line header used by print.aei_tbl and summary.aei_tbl.
.aei_tbl_header <- function(x) {
  q <- attr(x, "aei_query")
  parts <- character(0L)
  if (!is.null(q$endpoint)) parts <- c(parts, q$endpoint)
  if (!is.null(q$release))  parts <- c(parts, paste0("release=", q$release))
  if (!is.null(q$facet))    parts <- c(parts, paste0("facet=", q$facet))
  if (!is.null(q$country))  parts <- c(parts, paste0("country=", q$country))
  parts <- c(parts, sprintf("%d row%s", nrow(x), if (nrow(x) == 1L) "" else "s"))
  paste(parts, collapse = " \u00b7 ")
}
