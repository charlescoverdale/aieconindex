# aieconindex 0.1.1

Maintenance release in response to the CRAN team's email of 2026-05-31
(Prof Brian Ripley), which reported that the package left roughly 26 MB
in the check system's persistent storage and asked for a correction
before 2026-06-14.

## Cause

The `--run-donttest` check ran the `\donttest{}` example for `aei_link()`,
which fetched a release file from Hugging Face. That single example was
the only one in the package that did not redirect the cache to a
temporary directory first, so it wrote the downloaded data to
`tools::R_user_dir("aieconindex", "cache")` (`~/.cache/R/aieconindex`)
and left it there. The check that flags this is "checking for new files
in some other directories".

## Fix

1. The `aei_link()` example now redirects the cache to `tempdir()` via
   `options(aieconindex.cache_dir = tempdir())` and restores the option
   afterwards, like the other ten data-fetching examples.
2. As belt-and-braces, `aei_cache_dir()` now detects an `R CMD check`
   run (via `_R_CHECK_PACKAGE_NAME_`) and returns a session-temporary
   directory. The package therefore cannot write to persistent storage
   during any check, even if an example, test, or vignette omits the
   per-call redirect. Normal interactive use is unchanged.
3. Documentation cleanup: removed the `https://www.bls.gov/soc/`
   reference link from the package help page and the README. The page is
   valid in a browser but the bls.gov domain returns HTTP 403 to every
   automated agent, so the URL checker flagged it. The Standard
   Occupational Classification is still cited by name; the O*NET
   reference link is retained.

No other code changed. All network-dependent tests skip on CRAN, and the
vignette evaluates no chunks.

## Test environments

* Local: macOS 15 (arm64), R 4.5.2.
* Reproduced the CRAN team's exact check by running
  `R CMD check --as-cran --run-donttest` with
  `_R_CHECK_THINGS_IN_OTHER_DIRS_=true` and
  `_R_CHECK_THINGS_IN_TEMP_DIR_=true`.

## R CMD check results

Routine checks (no `--run-donttest`): 0 errors | 0 warnings | 0 notes.

Under `--run-donttest` with the directory-monitoring flags above:
"checking for new files in some other directories ... OK" and "checking
for detritus in the temp directory ... OK" both pass, and no files
remain under `tools::R_user_dir("aieconindex", "cache")`. The only NOTE
in that configuration is the elapsed time of the `aei_compare()`
`\donttest{}` example, which fetches two full releases over the network;
this is expected for a network example and does not appear in CRAN's
routine flavour checks.

## Possibly misspelled words

The DESCRIPTION mentions proper nouns, acronyms, and citation particles
that `aspell` flags, all intentional and correctly spelled: Anthropic,
Hugging Face, Claude, O*NET, Clio, AEI, Handa, Tamkin, Herfindahl,
Hirschman, et, al. `inst/WORDLIST` carries the full list.
