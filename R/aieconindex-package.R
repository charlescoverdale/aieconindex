#' aieconindex: Access the Anthropic Economic Index dataset
#'
#' Provides clean, tidy access to the Anthropic Economic Index (AEI)
#' dataset hosted on Hugging Face. Functions list available releases,
#' fetch raw and enriched usage tables, retrieve task statements,
#' request hierarchies, and country-level breakdowns. Data is cached
#' locally for subsequent calls.
#'
#' The Anthropic Economic Index is released by Anthropic under
#' Creative Commons Attribution 4.0 International (CC-BY-4.0). When
#' using this package to retrieve or redistribute that data, attribution
#' to Anthropic is required. See [aei_cite()] for citation strings.
#'
#' This product uses the Anthropic Economic Index data but is not
#' endorsed or certified by Anthropic.
#'
#' @references
#' Handa, K., Tamkin, A., McCain, M., Huang, S., Durmus, E., Heck, S.,
#' Mueller, J., Hong, J., Ritchie, S., Belonax, T., Troy, K. K.,
#' Amodei, D., Kaplan, J., Clark, J., and Ganguli, D. (2025). Which
#' Economic Tasks are Performed with AI? Evidence from Millions of
#' Claude Conversations. arXiv:2503.04761.
#' \url{https://arxiv.org/abs/2503.04761}
#'
#' Tamkin, A. et al. (2024). Clio: Privacy-Preserving Insights into
#' Real-World AI Use. arXiv:2412.13678.
#' \url{https://arxiv.org/abs/2412.13678}
#'
#' U.S. Department of Labor, Employment and Training Administration.
#' O*NET Database. \url{https://www.onetonline.org/}
#'
#' U.S. Bureau of Labor Statistics. Standard Occupational
#' Classification. \url{https://www.bls.gov/soc/}
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom stats setNames
#' @importFrom utils packageVersion read.csv
NULL
