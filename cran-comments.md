# aieconindex 0.1.0

This is a new submission.

## Test environments

* Local: macOS 14.x (arm64), R 4.5.2 — 0 errors, 0 warnings, 0 notes
* win-builder R-devel — submitted 2026-04-29
* GitHub Actions CI: to be added

## R CMD check results

0 errors | 0 warnings | 0 notes (locally)

## What this package does

Provides tidy R access to the Anthropic Economic Index (AEI) dataset
hosted on Hugging Face <https://huggingface.co/datasets/Anthropic/EconomicIndex>.
The AEI is a recurring open dataset (CC-BY-4.0) released by Anthropic
that maps usage of the Claude family of large language models to
occupations and tasks using the U.S. O*NET taxonomy and the Standard
Occupational Classification system. The methodology is documented in
Handa et al. (2025) <arXiv:2503.04761>; the privacy-preserving Clio
classification system is described in Tamkin et al. (2024)
<arXiv:2412.13678>.

The package follows the same architecture as several other CRAN
packages by the same author that wrap a single open dataset
(`fred`, `boe`, `hmrc`, `ons`, `comtrade`): cli/httr2 + an `_tbl` S3
class with provenance attributes + `tools::R_user_dir` cache.

## Network and cache policy

* No examples write outside `tempdir()`. Every `\donttest{}` example
  that touches the cache redirects via
  `options(aieconindex.cache_dir = tempdir())` first and restores via
  `options(op)` after.
* `tests/testthat/setup.R` redirects the cache option to a sub-directory
  of `tempdir()` for the entire test session, as belt-and-braces.
* All network-dependent tests skip on CRAN via `skip_on_cran()` and
  `skip_if_offline()`.
* No `\dontrun{}` in any example.
* The package contacts only `huggingface.co` (the dataset host) and
  uses no API key; the dataset is fully public.

## Anthropic non-endorsement

The DESCRIPTION explicitly notes that this product uses the Anthropic
Economic Index data but is not endorsed or certified by Anthropic.
The methodological source paper (Handa et al. 2025) is cited in the
DESCRIPTION, in `inst/CITATION`, and in the package-level Rd file.
The dataset's CC-BY-4.0 licence is acknowledged in `LICENSE.md` and
in the README.

## Possibly misspelled words

The DESCRIPTION mentions several proper nouns that lintr / `aspell`
will flag: "Anthropic", "Hugging Face", "Claude", "O*NET", "Clio".
These are the actual names of the dataset, host, model family,
taxonomy, and underlying classification system, all spelled as their
respective owners spell them. `inst/WORDLIST` carries the full list
of expected proper nouns and British English forms.
