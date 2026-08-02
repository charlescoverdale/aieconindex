# aieconindex 0.2.0

Support for the 2026-06-26 release and its new monthly-aggregate
schema, plus a live fallback so releases published after a package
version was built remain reachable.

## New release support

* Bundled metadata now includes `release_2026_06_26` (April and May
  2026 data, monthly cadence, Artifacts metrics, "Cadences" report).
* `aei_index()` recognises the monthly filename convention
  (`aei_<source>_<date>.csv`; the raw/enriched variant was dropped
  from filenames) and the new monthly schema. The `variant` argument
  is ignored for monthly releases. If a release breaks the filename
  convention expected for its epoch, the other epoch's pattern is
  tried before erroring.
* `aei_geography()` understands the monthly schema's `geo_level`
  column and ISO 3166-2 subregion codes, gains a `"subregion"` level,
  maps `"state_us"` onto US subregions (`geo_id` starting `"US-"`)
  for monthly releases, and now defaults to `release = "latest"`.
* `aei_compare()` chooses its default join keys from the schema the
  two releases share (`by = NULL` is the new default) and filters
  monthly releases, which can ship several calendar months in one
  file, to their most recent `date_start` window before joining.

## Live release resolution

* Release resolution (`"latest"`, ids, and dates) now falls back to
  the live Hugging Face directory listing when an identifier is not in
  the bundled table, so releases published after this package version
  was built resolve instead of erroring. The listing is fetched at
  most once per session; offline use degrades to the bundled list.
* `aei_index()` reports the file size before starting a download
  larger than 50 MB (the monthly usage CSVs exceed 200 MB).

## New functions

* `aei_labor_market()` fetches the standalone `labor_market_impacts`
  tables (`"job_exposure"`, `"task_penetration"`) that Anthropic
  publishes alongside the dated releases.

## Fixes

* `aei_concentration()` documentation claimed the input scale was
  detected automatically; it is not, and the docs now describe the
  actual behaviour. A new `rescale` argument normalises shares to
  percentages summing to 100 before computing HHI and CR_n, for use
  on filtered subsets whose shares no longer total 100.
* `aei_cite()` and `aei_releases()` now carry a report URL for the
  2026-03-24 release (previously `NA`).

# aieconindex 0.1.1

CRAN maintenance release addressing a check-system issue raised by the
CRAN team on 2026-05-31.

* The `\donttest{}` example for `aei_link()` fetched a release file into
  the persistent user cache (`tools::R_user_dir()`) rather than a
  temporary directory, so it left data behind on the CRAN check
  machines. The example now redirects the cache to `tempdir()`, matching
  every other example in the package.
* `aei_cache_dir()` now redirects to a session-temporary directory when
  it detects an `R CMD check` run, so the package cannot write to
  persistent storage during checks even if an example, test, or vignette
  omits the redirect.
* Removed the `bls.gov/soc/` reference link from the help page and
  README. The page returns HTTP 403 to automated URL checkers; the
  Standard Occupational Classification is still cited by name.

# aieconindex 0.1.0

Initial release.

## Discovery and download

* `aei_releases()` lists available Anthropic Economic Index releases on
  Hugging Face, blending bundled metadata with a live listing.
* `aei_files()` returns the recursive file tree of a release.
* `aei_index()` fetches the canonical usage CSV for a release, handling
  the wide-to-long schema change between the 2025-03-27 and 2025-09-15
  releases automatically.
* `aei_download()` is the lower-level escape hatch for fetching any
  file from a release by path.

## Structured access

* `aei_clusters()` returns the request-hierarchy tree (Clio output) as
  a parsed nested list. Released from 2025-09-15 onwards.
* `aei_tasks()` returns the bundled O*NET task statements (released
  with the 2025-03-27 snapshot).
* `aei_geography()` filters the long-format enriched table to country
  or US-state rows. Released from 2025-09-15 onwards.

## Analysis

* `aei_compare()` produces a release-on-release diff of the same metric
  across two AEI snapshots, returning shared keys plus `value_a`,
  `value_b`, `delta`, and `pct_change`.
* `aei_link()` is a generic merge helper that preserves the `aei_tbl`
  class and provenance metadata. Use it to splice the AEI to your own
  data on a shared key (country code, occupational identifier, cluster
  name, etc.). Supports left, inner, and full joins.
* `aei_concentration()` computes the Herfindahl-Hirschman Index, top-N
  concentration ratios (CR4 by default), and Shannon entropy on a
  vector of usage shares. Auto-detects the share column and supports
  per-group computation.

## Reproducibility

* `aei_cite()` returns a citation in plain text, BibTeX, or `bibentry`
  form, including the methodological source paper of Handa et al.
  (2025) by default.
* `aei_cache_info()`, `aei_cache_clear()`, and `aei_cache_dir()` manage
  the local data cache.

## S3 class

* `aei_tbl` class with `print`, `summary`, and `[` methods that
  preserve the `aei_query` provenance attribute (release id, source
  URL, fetch timestamp) across subsetting.
