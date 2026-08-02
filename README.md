# aieconindex

> Tidy R access to the Anthropic Economic Index dataset.

[![CRAN status](https://www.r-pkg.org/badges/version/aieconindex)](https://CRAN.R-project.org/package=aieconindex) [![CRAN downloads](https://cranlogs.r-pkg.org/badges/aieconindex)](https://cran.r-project.org/package=aieconindex) [![Total Downloads](https://cranlogs.r-pkg.org/badges/grand-total/aieconindex)](https://CRAN.R-project.org/package=aieconindex) [![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Data: CC-BY 4.0](https://img.shields.io/badge/data-CC--BY%204.0-blue.svg)](https://creativecommons.org/licenses/by/4.0/)

## Background

The [Anthropic Economic Index](https://www.anthropic.com/economic-index) (AEI) is a recurring open dataset that maps real Claude conversations to occupations and tasks. Anthropic classifies millions of conversations against the U.S. Department of Labor's [O*NET](https://www.onetonline.org/) task taxonomy and the Standard Occupational Classification (SOC) system, and publishes the resulting usage shares on [Hugging Face](https://huggingface.co/datasets/Anthropic/EconomicIndex) under CC-BY-4.0. Each release also splits conversations into automation-style interactions (the user delegates to Claude) and augmentation-style interactions (the user works through a task with Claude). From the September 2025 release onwards, the data is broken down by country and US state. Methodology is documented in [Handa et al. (2025)](https://arxiv.org/abs/2503.04761); the privacy-preserving classification pipeline is described in [Tamkin et al. (2024)](https://arxiv.org/abs/2412.13678).

Six releases have shipped between February 2025 and June 2026, covering Claude 3.5 Sonnet through the current model family. From June 2026 the index moved to calendar-month aggregates with country and subregion breakdowns, and Anthropic also publishes standalone labor market impact tables (job exposure and task penetration). `aieconindex` lists releases, fetches usage tables, retrieves task statements and request hierarchies, exposes country and subregion slices, fetches the labor market tables, caches downloads, and produces ready-made citations. Schema differences across releases are handled internally, and releases published after this package version was built still resolve via the live Hugging Face listing. Three runtime dependencies (`cli`, `httr2`, `jsonlite`) plus base R. No API key needed.

## Table of contents

- [Background](#background)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Function reference](#function-reference)
  - [Discovery](#discovery)
  - [Download](#download)
  - [Structured access](#structured-access)
  - [Analysis](#analysis)
  - [Reproducibility](#reproducibility)
  - [Cache management](#cache-management)
- [The aei_tbl class](#the-aei_tbl-class)
- [Common workflows](#common-workflows)
- [Releases covered](#releases-covered)
- [Caching](#caching)
- [Relationship to the Anthropic Python notebooks](#relationship-to-the-anthropic-python-notebooks)
- [Related work](#related-work)
- [Citation](#citation)
- [Contributing](#contributing)
- [Licensing and attribution](#licensing-and-attribution)

## Installation

```r
install.packages("aieconindex")

# or the development version
# install.packages("remotes")
remotes::install_github("charlescoverdale/aieconindex")
```

R 4.1.0 or later.

## Quick start

```r
library(aieconindex)

# 1. See what's available
aei_releases()
#> # AEI: releases · 6 rows
#>           release_id release_date               model
#> 1 release_2026_06_26   2026-06-26   All Claude models
#> 2 release_2026_03_24   2026-03-24 Claude Opus 4.5/4.6
#> 3 release_2026_01_15   2026-01-15   Claude Sonnet 4.5
#> 4 release_2025_09_15   2025-09-15     Claude Sonnet 4
#> 5 release_2025_03_27   2025-03-27   Claude 3.7 Sonnet
#> 6 release_2025_02_10   2025-02-10   Claude 3.5 Sonnet
#> ...

# 2. Look inside a release
aei_files("2025-09-15", recursive = TRUE)

# 3. Fetch the canonical usage table
df <- aei_index("2025-09-15", source = "claude_ai", variant = "enriched")

# 4. Slice to a country
uk <- aei_geography("2025-09-15", country = "GBR")

# 5. Cite the dataset
aei_cite("2025-09-15", format = "bibtex")
```

## Function reference

### Discovery

| Function | Returns |
|---|---|
| `aei_releases(live = TRUE)` | Available releases (live + bundled metadata) as an `aei_tbl` |
| `aei_files(release, recursive = TRUE)` | Recursive file tree for a release as an `aei_tbl` with `path`, `type`, `size_bytes` |

```r
aei_releases(live = FALSE)        # offline-safe (uses bundled metadata)
aei_files("latest")               # tree of the most recent release
aei_files("2025-03-27", recursive = FALSE)  # top-level only
```

### Download

| Function | Returns |
|---|---|
| `aei_index(release, source, variant)` | Canonical usage table as an `aei_tbl` |
| `aei_download(release, path)` | CSVs as `aei_tbl`, JSON as parsed list, other extensions as local path |

`aei_index()` locates the canonical usage CSV by file-pattern matching. Arguments:

- `source`: `"claude_ai"` (consumer product traffic) or `"1p_api"` (first-party API). Not all releases include both.
- `variant`: `"raw"` (counts and percentages from Anthropic's pipeline) or `"enriched"` (joined to O*NET / SOC metadata, with derived per-capita and tier metrics). Older releases may only ship one variant. Ignored for releases from 2026-06-26 onwards, which ship a single file per source.

```r
df_monthly  <- aei_index("2026-06-26", source = "claude_ai")
df_raw      <- aei_index("2026-03-24", source = "claude_ai", variant = "raw")
df_enriched <- aei_index("2025-09-15", source = "claude_ai", variant = "enriched")
df_api      <- aei_index("2026-06-26", source = "1p_api")
```

`aei_download()` fetches any path returned by `aei_files()`:

```r
soc       <- aei_download("2025-03-27", "SOC_Structure.csv")
hierarchy <- aei_download("2025-09-15",
                          "data/output/request_hierarchy_tree_claude_ai.json")
report    <- aei_download("2026-01-15", "aei_v4_appendix.pdf")  # returns local path
```

### Structured access

| Function | Returns |
|---|---|
| `aei_clusters(release, source)` | Request-hierarchy tree (Clio output) as a parsed nested list |
| `aei_tasks(release)` | O*NET task statements bundled with the release as an `aei_tbl` |
| `aei_geography(release, country, geography)` | Country, US-state, or subregion filter on the usage table |
| `aei_labor_market(table)` | Standalone labor market impacts tables (`"job_exposure"`, `"task_penetration"`) |

```r
# Clio-derived request hierarchy (from 2025-09-15 onwards)
tree <- aei_clusters("2025-09-15", source = "claude_ai")

# Bundled O*NET task statements (ships in 2025-03-27)
tasks <- aei_tasks("2025-03-27")

# UK country slice (geographic facets ship from 2025-09-15 onwards)
uk <- aei_geography("2025-09-15", country = "GBR")

# Australia country slice
au <- aei_geography("2025-09-15", country = "AUS")

# US state-level breakdown
us_states <- aei_geography("2025-09-15", geography = "state_us")

# All subregions in the monthly schema (2026-06-26 onwards)
subs <- aei_geography("2026-06-26", geography = "subregion")

# Standalone labor market impacts tables
exposure    <- aei_labor_market("job_exposure")
penetration <- aei_labor_market("task_penetration")
```

Country codes are ISO-3 (`"GBR"`, `"AUS"`, `"USA"`). In the monthly schema (2026-06-26 onwards) subregions carry ISO 3166-2 codes, so US states appear as `"US-CA"`, `"US-NY"`, and so on. Releases before 2025-09-15 have no geographic data; the function errors informatively.

### Analysis

| Function | Returns |
|---|---|
| `aei_compare(release_a, release_b, ...)` | Release-on-release diff with `value_a`, `value_b`, `delta`, `pct_change`; join keys auto-detected from the shared schema |
| `aei_link(x, y, by, type)` | Generic merge that preserves the `aei_tbl` class; for splicing AEI to user-supplied data on a shared key |
| `aei_concentration(x, share_col, group_cols, top_n)` | HHI, top-N concentration ratio, Shannon entropy on usage shares |

```r
# How did the cluster shares move between Sept 2025 and March 2026?
diff <- aei_compare("2025-09-15", "2026-03-24")
head(diff[order(-abs(diff$delta)), ])

# Splice AEI country shares to your own GDP-per-capita table
overlay <- data.frame(
  geo_id = c("GBR", "AUS", "USA"),
  gdp_pc = c(48000, 65000, 80000)
)
joined <- aei_link(aei_geography("2025-09-15"), overlay, by = "geo_id")

# How concentrated is UK Claude.ai usage across O*NET tasks?
uk <- aei_geography("2025-09-15", country = "GBR")
uk_tasks <- uk[uk$facet == "onet_task" & uk$variable == "onet_task_pct", ]
aei_concentration(uk_tasks)
```

`aei_link()` is a thin wrapper over `base::merge()` that preserves the `aei_tbl` class and provenance metadata, supports left / inner / full joins, and warns when a join produces zero rows. Use it to attach occupational crosswalks (SOC, ANZSCO, ISCO, SOC2020 UK), national labour-force data (ONS, BLS OEWS, ABS), or anything else keyed on country code or task identifier.

### Reproducibility

| Function | Returns |
|---|---|
| `aei_cite(release, format, method = TRUE)` | Citation in plain text, BibTeX, or `bibentry` form |

By default `aei_cite()` returns both the dataset citation and [Handa et al. (2025)](https://arxiv.org/abs/2503.04761). Set `method = FALSE` for the dataset only.

```r
aei_cite()                                         # text, project-wide, with paper
aei_cite("2025-09-15", format = "bibtex")          # BibTeX, both refs
aei_cite("2026-03-24", format = "bibentry")        # bibentry object (multi-entry)
aei_cite(format = "text", method = FALSE)          # dataset only
```

### Cache management

| Function | Returns |
|---|---|
| `aei_cache_dir()` | Path of the cache directory (override-aware) |
| `aei_cache_info()` | List with `dir`, `n_files`, `size_bytes`, `size_human`, `files` |
| `aei_cache_clear()` | Clears the cache; invisible NULL |

## The aei_tbl class

All data-returning functions emit an `aei_tbl`: a `data.frame` subclass with provenance metadata stored in the `aei_query` attribute. The metadata carries `endpoint`, the resolved release identifier, the source URL, and the fetch timestamp; it is preserved across row and column subsetting.

```r
df <- aei_index("2025-09-15")
attr(df, "aei_query")
#> $endpoint   "index"
#> $release    "release_2025_09_15"
#> $facet      "raw/claude_ai"
#> $source_url "https://huggingface.co/datasets/Anthropic/EconomicIndex/.../aei_raw_claude_ai_*.csv"
#> $fetched_at "2026-04-28 18:34:00 BST"

# Custom print method shows the provenance header
print(df)
#> # AEI: index · release=release_2025_09_15 · facet=raw/claude_ai · 12345 rows
#> ...

# Subsetting preserves the class and attribute
sub <- df[df$value > 1, ]
class(sub)
#> [1] "aei_tbl" "data.frame"
```

The class inherits from `data.frame`, so any function that takes a data frame works without conversion. Drop the class with `as.data.frame()` if you need a plain frame.

## Common workflows

**Pin a release for production.** Default `release = "latest"` resolves to the most recent release at call time, which is fine for exploration but unsuitable for reproducible pipelines. Pin a release identifier explicitly:

```r
RELEASE <- "2025-09-15"  # or "release_2025_09_15"
df <- aei_index(RELEASE, source = "claude_ai", variant = "enriched")
```

**Replicate an Anthropic figure.** Anthropic ships Python replication notebooks (`v2_report_replication.ipynb`) inside several releases. To replicate the augmentation-vs-automation headline figure in R:

```r
df <- aei_download("2025-03-27", "automation_vs_augmentation_v2.csv")
df$family <- ifelse(df$interaction_type %in% c("directive", "feedback loop"),
                    "Automation", "Augmentation")
```

**Country exposure ranking.** Top O*NET tasks for the UK by share of Claude.ai usage:

```r
uk <- aei_geography("2025-09-15", country = "GBR")
top <- subset(uk, facet == "onet_task" & variable == "onet_task_pct")
top <- top[order(-top$value), ][1:15, c("cluster_name", "value")]
```

**Cross-country comparison.** Per-capita usage index for selected economies:

```r
df <- aei_index("2025-09-15", source = "claude_ai", variant = "enriched")
country_overall <- subset(df,
  geography == "country" &
  variable  == "usage_per_capita_index" &
  cluster_name == "not_classified" &
  level == 0
)
country_overall <- country_overall[order(-country_overall$value), ]
```

**Cite in a paper.** Drop the BibTeX form straight into your `.bib`:

```r
cat(aei_cite("2025-09-15", format = "bibtex"), file = "refs.bib", append = TRUE)
```

## Releases covered

The package recognises every release published to Hugging Face up to 2026-06-26. Releases published after this package version was built are discovered automatically via the Hugging Face tree API: they appear in `aei_releases()`, resolve in every data function (including `"latest"`), and default to the newest known schema.

| Release | Headline model | Notes |
|---|---|---|
| `release_2025_02_10` | Claude 3.5 Sonnet | Initial release; O*NET task mappings; automation vs augmentation |
| `release_2025_03_27` | Claude 3.7 Sonnet | Cluster-level insights; v2 report replication notebook |
| `release_2025_09_15` | Claude Sonnet 4 | Geographic + first-party API data added; long-format schema |
| `release_2026_01_15` | Claude Sonnet 4.5 | Economic primitives added |
| `release_2026_03_24` | Claude Opus 4.5/4.6 | Learning curves added |
| `release_2026_06_26` | All Claude models | Monthly cadence (April + May 2026); Artifacts metrics; new geo/category/metric schema |

Each release ships its own `data_documentation.md` on Hugging Face. The package's `aei_releases()` blends bundled metadata (model, report URL) with a live Hugging Face listing. Anthropic also publishes a standalone `labor_market_impacts` directory (job exposure and task penetration tables), available via `aei_labor_market()`.

## Caching

Downloaded files are cached under the path returned by `aei_cache_dir()`, which defaults to `tools::R_user_dir("aieconindex", "cache")`. Override before the first call:

```r
options(aieconindex.cache_dir = "/your/preferred/path")
```

Cache is keyed by release identifier and relative path, so re-downloads are byte-identical to the original.

```r
aei_cache_info()
#> $dir         "/Users/.../aieconindex/cache"
#> $n_files     3
#> $size_bytes  126839425
#> $size_human  "121.0 MB"
#> $files       <data.frame: 3 rows>

aei_cache_clear()  # removes all cached files
```

The latest release usage CSVs are large (the June 2026 `claude_ai` file exceeds 200 MB), so the first call to a fresh release is bandwidth-heavy; `aei_index()` reports the file size before starting any download over 50 MB. Subsequent calls are served from disk.

## Relationship to the Anthropic Python notebooks

Anthropic ships its own replication code as Jupyter notebooks inside several releases (e.g. `release_2025_03_27/v2_report_replication.ipynb`). For exact figure replication, use those. `aieconindex` is the R-side equivalent of Hugging Face's Python `datasets` loader: typed, cached access to the same source files, with downstream analysis left to you.

## Related work

- [Anthropic/EconomicIndex on Hugging Face](https://huggingface.co/datasets/Anthropic/EconomicIndex): the upstream dataset.
- [Handa et al. (2025), arXiv:2503.04761](https://arxiv.org/abs/2503.04761): the methodological source paper.
- [Tamkin et al. (2024), arXiv:2412.13678](https://arxiv.org/abs/2412.13678): the Clio system paper.
- [Felten, Raj, and Seamans (2021)](https://doi.org/10.1002/smj.3286): the AI Occupational Exposure (AIOE) measure, on the same O*NET task taxonomy.
- [Acemoglu and Restrepo (2020)](https://doi.org/10.1086/705716): the canonical automation-and-jobs paper referenced by AEI's interaction-type framework.
- [O*NET Database](https://www.onetonline.org/): the U.S. Department of Labor's task taxonomy.
- Standard Occupational Classification (SOC): the U.S. Bureau of Labor Statistics' occupational classification system.
- [Anthropic Economic Futures](https://www.anthropic.com/economic-futures): Anthropic's broader economic research programme.

## Related packages

| Package | Description |
|---|---|
| [`inequality`](https://github.com/charlescoverdale/inequality) | Inequality and poverty measurement (labour-market distributional context) |
| [`ons`](https://github.com/charlescoverdale/ons) | UK labour market data (employment, wages by occupation) |
| [`fred`](https://github.com/charlescoverdale/fred) | US labour market data (employment, productivity, occupational wages) |
| [`readoecd`](https://github.com/charlescoverdale/readoecd) | OECD international labour and skills data |

## Citation

Cite both the package and the underlying dataset:

```r
citation("aieconindex")
aei_cite("2025-09-15", format = "bibtex")
```

`aei_cite()` returns the dataset citation alongside [Handa et al. (2025)](https://arxiv.org/abs/2503.04761), the methodological source paper.

## Contributing

Issues and pull requests welcome at https://github.com/charlescoverdale/aieconindex/issues. Useful contributions for v0.3 include:

- Occupational crosswalks (SOC ↔ ANZSCO ↔ ISCO ↔ SOC2010_UK)
- Joins to ONS Labour Force Survey, BLS OEWS, ABS Labour Force
- Replication helpers for specific Anthropic figures
- Vignettes demonstrating multi-release comparisons

For Anthropic-introduced schema changes that break `aei_index()` or `aei_geography()`, please open an issue with a sample of the new file structure (output of `aei_files(<new_release>)`).

## Licensing and attribution

This package is released under the [MIT License](LICENSE).

The underlying Anthropic Economic Index dataset is released by Anthropic under [Creative Commons Attribution 4.0 International (CC-BY-4.0)](https://creativecommons.org/licenses/by/4.0/). When using this package to retrieve or redistribute that data, attribution to Anthropic and to [Handa et al. (2025)](https://arxiv.org/abs/2503.04761) is required. Use `aei_cite()` for ready-made citation strings.

The bundled O*NET and SOC reference data (when accessed through the AEI) inherit their respective licences. See the [O*NET licensing page](https://www.onetonline.org/help/license) and the BLS Standard Occupational Classification documentation.

This product uses the Anthropic Economic Index data but is not endorsed or certified by Anthropic.
