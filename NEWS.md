# aieconindex 0.2.0

## New analysis functions

* `aei_compare()` produces a release-on-release diff of the same metric
  across two AEI snapshots, returning shared keys plus `value_a`,
  `value_b`, `delta`, and `pct_change`. Designed for the long-format
  schema introduced in the 2025-09-15 release.
* `aei_link()` is a generic merge helper that preserves the `aei_tbl`
  class and provenance metadata. Use it to splice the AEI to your own
  data on a shared key (country code, occupational identifier,
  release-stable cluster name, etc.). Supports left, inner, and full
  joins; warns when a join returns zero rows.
* `aei_concentration()` computes Herfindahl-Hirschman Index, top-N
  concentration ratios (CR4 by default), and Shannon entropy on a
  vector of usage shares. Auto-detects the share column from
  long-format AEI tables (`value`) or wide-format (`pct`). Optional
  `group_cols` argument computes metrics within groups.

## Documentation

* README rewritten with a plain-language background section explaining
  what the AEI is, how it came about, what the data covers, what gaps
  in R-side tooling motivated the package, and how the design choices
  (O*NET taxonomy, Clio privacy classification, augmentation vs
  automation) affect interpretation.
* Companion R Journal-style paper added under `paper/rj/` with three
  real-data figures generated via the package itself.

# aieconindex 0.1.0

* Initial release.
* `aei_releases()` lists available Anthropic Economic Index releases on Hugging Face.
* `aei_index()` fetches raw or enriched usage tables for a release.
* `aei_clusters()` returns the request-hierarchy tree (cluster names and descriptions).
* `aei_tasks()` returns O*NET task statements for a release.
* `aei_geography()` returns country-level usage breakdowns (release dependent).
* `aei_cite()` returns BibTeX or plain-text citations for the dataset and a release.
* `aei_cache_info()` and `aei_cache_clear()` manage the local data cache.
* `aei_tbl` S3 class with `print`, `summary`, and `[` methods, carrying provenance attributes.
