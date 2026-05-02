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
