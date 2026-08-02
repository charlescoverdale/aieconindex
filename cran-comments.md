# aieconindex 0.2.0

Feature release adding support for the Anthropic Economic Index's
2026-06-26 release, which changed both the filename convention and the
data schema, plus a live fallback so releases published after a package
version is built remain reachable. Full details in NEWS.md.

## Test environments

* Local: macOS 15 (arm64), R 4.5.2.
* `R CMD check --as-cran`.

## R CMD check results

0 errors | 0 warnings | 0 notes.

All network-dependent tests skip on CRAN, the vignette evaluates no
chunks, all examples redirect the download cache to `tempdir()`, and
`aei_cache_dir()` additionally redirects to a session-temporary
directory whenever `_R_CHECK_PACKAGE_NAME_` is set, so checks cannot
write to persistent storage.

## Possibly misspelled words

The DESCRIPTION mentions proper nouns and acronyms that `aspell`
flags, all intentional and correctly spelled: Anthropic, Hugging Face,
Claude, O*NET, Clio, AEI, Handa, Tamkin, Herfindahl, Hirschman, et,
al. `inst/WORDLIST` carries the full list.
