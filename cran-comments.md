# aieconindex 0.1.0

Resubmission (same version) following pre-test feedback from Uwe Ligges
on 2026-05-10. Four issues from the pre-test NOTE addressed:

1. **CITATION file fails when package is not installed** — the original
   `inst/CITATION` used `utils::packageVersion("aieconindex")` which
   only resolves after installation. Replaced with the
   CRAN-recommended pattern using `meta$Version` from the
   `tools::readCitationFile` context.
2. **Invalid file URI in README** (`paper/rj/`) — replaced the
   relative-path link with the absolute GitHub URL so CRAN's URL
   checker can resolve it.
3. **arXiv references in the Description field** — switched both
   citations from the deprecated `<arXiv:YYMM.NNNNN>` format to the
   CRAN-current `<doi:10.48550/arXiv.YYMM.NNNNN>` format.
4. **Possibly misspelled words list** updated below.

Per CRAN policy for pre-acceptance resubmissions, version remains
0.1.0. NEWS.md is unchanged.

## Test environments

* Local: macOS 14.x (arm64), R 4.5.2 — 0 errors, 0 warnings, 0 notes
* GitHub Actions CI: to be added

## R CMD check results

0 errors | 0 warnings | 0 notes (locally)

## What this package does

Provides tidy R access to the Anthropic Economic Index (AEI) dataset
hosted on Hugging Face <https://huggingface.co/datasets/Anthropic/EconomicIndex>.
The AEI is a recurring open dataset (CC-BY-4.0) released by Anthropic
that maps usage of the Claude family of large language models to
occupations and tasks using the U.S. O*NET taxonomy and the Standard
Occupational Classification system.

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

The DESCRIPTION mentions several proper nouns, acronyms, and citation
particles that lintr / `aspell` will flag, all of which are intentional
and correctly spelled:

* **Anthropic** — the company that releases the dataset
* **Hugging Face** — the platform that hosts the dataset
* **Claude** — the large language model family
* **O*NET** — U.S. Department of Labor's task taxonomy
* **Clio** — Anthropic's privacy-preserving classification system
* **AEI** — short form of Anthropic Economic Index
* **Handa**, **Tamkin** — first authors of the cited papers
* **Herfindahl**, **Hirschman** — the surnames in the
  Herfindahl-Hirschman Index, named after Albert O. Hirschman and
  Orris C. Herfindahl
* **et**, **al** — components of the standard "et al." citation form

`inst/WORDLIST` carries the full list.
