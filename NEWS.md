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
