#' Citation strings for the Anthropic Economic Index
#'
#' Returns a citation for either the Anthropic Economic Index project
#' as a whole or a specific release, in the requested format. The
#' Anthropic Economic Index data is released under Creative Commons
#' Attribution 4.0 International (CC-BY-4.0); attribution is required
#' when redistributing the data.
#'
#' @details
#' For `release = "all"` (the default), the citation refers to the
#' methodological source paper: Handa, K. et al. (2025), "Which
#' Economic Tasks are Performed with AI? Evidence from Millions of
#' Claude Conversations" (arXiv:2503.04761). For a specific release,
#' the citation refers to the dataset snapshot at that release on
#' Hugging Face, with the headline model and the Anthropic report PDF
#' included when one is bundled.
#'
#' Hugging Face datasets do not currently issue DOIs by default; the
#' `url` field is the stable Hugging Face path. The methodological
#' source paper is on arXiv and has a permanent identifier
#' (arXiv:2503.04761).
#'
#' @param release A release identifier, or `"all"` (the default) to cite
#'   the project rather than a specific release.
#' @param format One of `"text"`, `"bibtex"`, or `"bibentry"`.
#' @param method Logical. If `TRUE` (the default), include the
#'   methodological source paper (Handa et al. 2025) in the BibTeX or
#'   bibentry output. Set to `FALSE` to return the dataset citation
#'   only.
#'
#' @references
#' Handa, K., Tamkin, A., McCain, M., Huang, S., Durmus, E., Heck, S.,
#' Mueller, J., Hong, J., Ritchie, S., Belonax, T., Troy, K. K.,
#' Amodei, D., Kaplan, J., Clark, J., and Ganguli, D. (2025). Which
#' Economic Tasks are Performed with AI? Evidence from Millions of
#' Claude Conversations. arXiv:2503.04761. \url{https://arxiv.org/abs/2503.04761}
#'
#' Tamkin, A. et al. (2024). Clio: Privacy-Preserving Insights into
#' Real-World AI Use. arXiv:2412.13678.
#' \url{https://arxiv.org/abs/2412.13678}
#'
#' @return A character vector for `"text"` and `"bibtex"`; a `bibentry`
#'   object (possibly with multiple entries) for `"bibentry"`.
#'
#' @family reproducibility
#' @export
#' @examples
#' aei_cite()
#' aei_cite("2026-03-24", format = "bibtex")
#' aei_cite("2025-09-15", format = "bibentry")
#' aei_cite(format = "text", method = FALSE)
aei_cite <- function(release = "all",
                     format = c("text", "bibtex", "bibentry"),
                     method = TRUE) {
  format <- match.arg(format)
  if (identical(release, "all")) {
    title <- "The Anthropic Economic Index"
    year  <- "2025"
    note  <- "Hugging Face dataset, released CC-BY-4.0"
    key   <- "aei"
    url   <- "https://huggingface.co/datasets/Anthropic/EconomicIndex"
    report_url <- NA_character_
  } else {
    release_id <- .aei_resolve_release(release)
    rel <- .aei_known_releases
    row <- rel[rel$release_id == release_id, , drop = FALSE]
    title <- sprintf("The Anthropic Economic Index, %s release", release_id)
    year  <- format(if (nrow(row)) row$release_date[1L] else Sys.Date(), "%Y")
    note  <- if (nrow(row)) sprintf("Headline model: %s. CC-BY-4.0.", row$model[1L])
             else "CC-BY-4.0"
    key   <- paste0("aei_", sub("release_", "", release_id))
    url   <- paste0("https://huggingface.co/datasets/Anthropic/EconomicIndex/tree/main/", release_id)
    report_url <- if (nrow(row)) row$report_url[1L] else NA_character_
  }

  method_text   <- "Handa, K. et al. (2025). Which Economic Tasks are Performed with AI? Evidence from Millions of Claude Conversations. arXiv:2503.04761."
  method_bibtex <- paste0(
    "@misc{handa2025economic,\n",
    "  author = {Handa, Kunal and Tamkin, Alex and McCain, Miles and Huang, Saffron and Durmus, Esin and Heck, Sarah and Mueller, Jared and Hong, Jerry and Ritchie, Stuart and Belonax, Tim and Troy, Kevin K. and Amodei, Dario and Kaplan, Jared and Clark, Jack and Ganguli, Deep},\n",
    "  title = {Which Economic Tasks are Performed with AI? Evidence from Millions of Claude Conversations},\n",
    "  year = {2025},\n",
    "  note = {arXiv:2503.04761},\n",
    "  url = {https://arxiv.org/abs/2503.04761}\n",
    "}"
  )

  if (format == "text") {
    txt <- sprintf("Anthropic (%s). %s. %s Available at %s.",
                   year, title, note, url)
    if (!is.na(report_url)) {
      txt <- paste0(txt, " Report: ", report_url)
    }
    if (isTRUE(method)) {
      txt <- paste(txt, method_text, sep = "\n\n")
    }
    return(txt)
  }
  if (format == "bibtex") {
    note_full <- if (!is.na(report_url)) sprintf("%s Report: %s", note, report_url) else note
    data_bib <- sprintf(
      "@misc{%s,\n  author = {{Anthropic}},\n  title = {%s},\n  year = {%s},\n  note = {%s},\n  url = {%s}\n}",
      key, title, year, note_full, url
    )
    if (isTRUE(method)) {
      return(paste(data_bib, method_bibtex, sep = "\n\n"))
    }
    return(data_bib)
  }
  data_be <- utils::bibentry(
    bibtype = "Misc",
    key     = key,
    title   = title,
    author  = utils::person("Anthropic"),
    year    = year,
    note    = if (!is.na(report_url)) sprintf("%s Report: %s", note, report_url) else note,
    url     = url
  )
  if (!isTRUE(method)) return(data_be)
  method_be <- utils::bibentry(
    bibtype = "Misc",
    key     = "handa2025economic",
    title   = "Which Economic Tasks are Performed with AI? Evidence from Millions of Claude Conversations",
    author  = c(
      utils::person("Kunal", "Handa"),
      utils::person("Alex", "Tamkin"),
      utils::person("Miles", "McCain"),
      utils::person("Saffron", "Huang"),
      utils::person("Esin", "Durmus"),
      utils::person("Sarah", "Heck"),
      utils::person("Jared", "Mueller"),
      utils::person("Jerry", "Hong"),
      utils::person("Stuart", "Ritchie"),
      utils::person("Tim", "Belonax"),
      utils::person(c("Kevin", "K."), "Troy"),
      utils::person("Dario", "Amodei"),
      utils::person("Jared", "Kaplan"),
      utils::person("Jack", "Clark"),
      utils::person("Deep", "Ganguli")
    ),
    year    = "2025",
    note    = "arXiv:2503.04761",
    url     = "https://arxiv.org/abs/2503.04761"
  )
  c(data_be, method_be)
}
