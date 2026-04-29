# aieconindex

> Tidy R access to the Anthropic Economic Index dataset.

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Data: CC-BY 4.0](https://img.shields.io/badge/data-CC--BY%204.0-blue.svg)](https://creativecommons.org/licenses/by/4.0/)

## Background

In early 2025 Anthropic published a new kind of economic dataset. Until then, almost everything we knew about how AI was actually being used in the economy came from one of two places: surveys (asking people what they used AI for) or indirect proxies (working out which jobs theoretically had the most AI-exposed tasks, and assuming usage followed exposure). The [Anthropic Economic Index](https://www.anthropic.com/economic-index) (AEI) took a more direct approach. Anthropic took millions of real Claude conversations, classified each one against the U.S. Department of Labor's [O*NET](https://www.onetonline.org/) task taxonomy and its [Standard Occupational Classification](https://www.bls.gov/soc/) system, and reported the resulting usage shares as open data. The methodology is documented in [Handa et al. (2025)](https://arxiv.org/abs/2503.04761). The privacy-preserving system that does the classification, in which Claude itself summarises other Claude conversations under tight rules, is described in [Tamkin et al. (2024)](https://arxiv.org/abs/2412.13678).

The dataset is published on [Hugging Face](https://huggingface.co/datasets/Anthropic/EconomicIndex) as a recurring set of snapshots, all released under CC-BY-4.0. Five releases have shipped between February 2025 and March 2026, covering Claude 3.5 Sonnet through Opus 4.5/4.6. Each release reports, for the time window it covers, the share of classified conversations that mapped to each O*NET task and each SOC occupational group, plus a split between automation-style interactions (where the user delegates a task to Claude) and augmentation-style interactions (where the user works through a task with Claude). From the September 2025 release onwards, the data is also broken down by country and US state, and a hierarchical clustering of request types produced by Clio is shipped as JSON. From the January 2026 release onwards, a set of derived "economic primitives" sit alongside the raw shares.

The data is open, the methodology is documented, and Anthropic ships replication notebooks alongside each release. But for anyone working in R, the dataset was inconvenient to use:

- The replication notebooks are Python only. There was no R wrapper.
- The directory layout changed between the March 2025 and September 2025 releases, moving from wide-format release-root CSVs to a long-format `data/output/` layout. Code written for one release would silently break on the next.
- There were no off-the-shelf helpers for the analyses people actually wanted: pulling out a single country, ranking O*NET tasks by share, comparing two releases. Every analysis started from raw CSV wrangling.
- Citation was scattered. The methodological source paper (Handa et al. 2025), the Clio paper (Tamkin et al. 2024), and the per-release report PDFs all lived in different places.
- There was no bridge from AEI usage shares to national labour statistics. Anyone wanting to weight AEI shares by working-age employment from the UK Office for National Statistics, the U.S. Bureau of Labor Statistics OEWS, or the Australian Bureau of Statistics Labour Force survey had to assemble their own crosswalks.

`aieconindex` is the R-side answer to those gaps. It lists releases, fetches the raw and enriched usage tables, retrieves task statements and request hierarchies, exposes country and US-state slices through a single function, caches downloads locally, and produces ready-made citations that include the methodological source paper by default. Schema differences across releases are handled internally; pinning a release id keeps downstream pipelines reproducible. No API key is required. Three runtime dependencies (`cli`, `httr2`, `jsonlite`) plus base R.

A companion paper (R Journal style) lives under [`paper/rj/`](paper/rj/) in this repo.

## Table of contents

- [Background](#background)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Three design choices worth knowing](#three-design-choices-worth-knowing)
- [Function reference](#function-reference)
  - [Discovery](#discovery)
  - [Download](#download)
  - [Structured access](#structured-access)
  - [Reproducibility](#reproducibility)
  - [Cache management](#cache-management)
- [The aei_tbl class](#the-aei_tbl-class)
- [Common workflows](#common-workflows)
- [Releases covered](#releases-covered)
- [Caching](#caching)
- [Relationship to the Anthropic Python notebooks](#relationship-to-the-anthropic-python-notebooks)
- [Limitations](#limitations)
- [Related work](#related-work)
- [Citation](#citation)
- [Contributing](#contributing)
- [Licensing and attribution](#licensing-and-attribution)

## Installation

From GitHub (development version):

```r
# install.packages("remotes")
remotes::install_github("charlescoverdale/aieconindex")
```

CRAN release: planned.

The package is pure R with three runtime dependencies (`cli`, `httr2`, `jsonlite`) and the base `tools`, `stats`, and `utils` packages. R 4.1.0 or later is required. No API key is needed.

## Quick start

```r
library(aieconindex)

# 1. See what's available
aei_releases()
#> # AEI: releases · 5 rows
#>           release_id release_date               model
#> 1 release_2026_03_24   2026-03-24 Claude Opus 4.5/4.6
#> 2 release_2026_01_15   2026-01-15   Claude Sonnet 4.5
#> 3 release_2025_09_15   2025-09-15     Claude Sonnet 4
#> 4 release_2025_03_27   2025-03-27   Claude 3.7 Sonnet
#> 5 release_2025_02_10   2025-02-10   Claude 3.5 Sonnet
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

## Three design choices worth knowing

1. **Task taxonomy.** Each Claude conversation is classified against the [O*NET task statements](https://www.onetonline.org/), the same task descriptions used by the U.S. Department of Labor and by the AI exposure literature ([Felten, Raj, and Seamans 2021](https://doi.org/10.1002/smj.3286); [Acemoglu and Restrepo 2020](https://doi.org/10.1086/705716)). This makes AEI directly comparable to existing exposure measures.
2. **Privacy-preserving classification.** Classification runs through [Clio](https://arxiv.org/abs/2412.13678). Cluster summaries that fail Clio's privacy checks (low cell counts, identifying information) are dropped before publication. Users see only aggregated counts and shares, never raw conversations.
3. **Augmentation versus automation.** Conversations are tagged with one of six interaction types: directive, feedback loop, task iteration, learning, validation, or none. Following [Handa et al. (2025)](https://arxiv.org/abs/2503.04761), directive and feedback-loop interactions are read as automation; task iteration, learning, and validation as augmentation.

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

`aei_index()` is a convenience wrapper that locates the canonical usage CSV by file-pattern matching (the AEI naming convention has shifted across releases). Arguments:

- `source` is one of `"claude_ai"` (Claude.ai consumer product traffic) or `"1p_api"` (first-party API traffic). Not all releases include both.
- `variant` is one of `"raw"` (counts and percentages straight from Anthropic's pipeline) or `"enriched"` (joined to O*NET / SOC metadata, with derived per-capita and tier metrics). Older releases may only ship one variant.

```r
df_raw      <- aei_index("2026-03-24", source = "claude_ai", variant = "raw")
df_enriched <- aei_index("2025-09-15", source = "claude_ai", variant = "enriched")
df_api      <- aei_index("2026-03-24", source = "1p_api",    variant = "raw")
```

`aei_download()` is the lower-level escape hatch. Pass any path returned by `aei_files()`:

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
| `aei_geography(release, country, geography)` | Country or US-state filter on the enriched table |

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
```

`aei_geography()` filters the enriched long-format table on the `geography` column. Country codes are ISO-3 in the enriched data (`"GBR"`, `"AUS"`, `"USA"`). Releases before 2025-09-15 do not contain geographic data and the function errors informatively.

### Reproducibility

| Function | Returns |
|---|---|
| `aei_cite(release, format, method = TRUE)` | Citation in plain text, BibTeX, or `bibentry` form |

By default `aei_cite()` includes the methodological source paper of [Handa et al. (2025)](https://arxiv.org/abs/2503.04761) alongside the dataset citation, because attribution under the dataset's CC-BY licence is required for any redistribution. Set `method = FALSE` to return only the dataset citation.

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

The package recognises every release published to Hugging Face up to 2026-03-24 and discovers any newer releases automatically via the Hugging Face tree API.

| Release | Headline model | Notes |
|---|---|---|
| `release_2025_02_10` | Claude 3.5 Sonnet | Initial release; O*NET task mappings; automation vs augmentation |
| `release_2025_03_27` | Claude 3.7 Sonnet | Cluster-level insights; v2 report replication notebook |
| `release_2025_09_15` | Claude Sonnet 4 | Geographic + first-party API data added; long-format schema |
| `release_2026_01_15` | Claude Sonnet 4.5 | Economic primitives added |
| `release_2026_03_24` | Claude Opus 4.5/4.6 | Learning curves added |

Each release ships its own `data_documentation.md` on Hugging Face. The package's `aei_releases()` blends bundled metadata (model, report URL) with a live Hugging Face listing.

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

The latest release usage CSVs are around 100 MB each, so the first call to a fresh release is bandwidth-heavy. Subsequent calls are served from disk.

## Relationship to the Anthropic Python notebooks

Anthropic ships its own replication code as Jupyter notebooks (Python) inside several releases: for example, `release_2025_03_27/v2_report_replication.ipynb` reproduces the figures in the corresponding report PDF.

`aieconindex` is a complement to that workflow, not a port. The package gives you typed, cached, R-side access to the same source CSVs and JSONs, leaving downstream analysis to you. If you want to reproduce a specific Anthropic figure, the notebook is the most reliable starting point. If you want to feed AEI data into an existing R pipeline (joining with ONS Labour Force Survey, BLS OEWS, or ABS Labour Force data; weighting by national working-age employment), this package is the most direct route.

The Hugging Face Python `datasets` library can also load the dataset (`datasets.load_dataset("Anthropic/EconomicIndex")`); `aieconindex` is the R-side equivalent for that workflow.

## Limitations

1. **Coverage bias.** AEI usage data reflects who uses Claude. The user base skews toward English speakers, knowledge workers, and software developers; the dataset is not a labour-force-representative sample of any economy.
2. **Proprietary measurement.** The Clio classification pipeline that produces the cluster hierarchies is Anthropic's. Users cannot independently audit the cluster assignments beyond what is described in [Tamkin et al. (2024)](https://arxiv.org/abs/2412.13678).
3. **Cross-release comparability is not automatic.** Both the underlying Claude model (3.5 Sonnet through Opus 4.5/4.6) and the Clio version change between releases. Pipelines that compare two releases should treat the comparison as model-version-dependent. See each release's `data_documentation.md` for the authoritative caveat list.
4. **Schema drift across releases.** The AEI restructured its directory layout between 2025-03-27 and 2025-09-15, moving from wide-format release-root CSVs to a long-format `data/output/` layout. `aei_index()` and `aei_geography()` paper over this with file-pattern heuristics. If Anthropic restructures again, the heuristics will break and the package will need an update.
5. **Network-dependent.** Almost every function fetches from Hugging Face on first call. Downstream analysis pipelines should pin a release id rather than `"latest"` to remain reproducible across re-runs.
6. **Large downloads.** Latest releases ship usage CSVs of ~100 MB each. The cache (default location: `tools::R_user_dir("aieconindex", "cache")`) avoids re-downloading, but the first call to a new release is bandwidth-heavy.
7. **Geographic data only from 2025-09-15.** Earlier releases do not contain geographic facets.
8. **Standalone task statements only in 2025-03-27.** Later releases reference O*NET implicitly through the enriched index file rather than redistributing the statements.

## Related work

- [Anthropic/EconomicIndex on Hugging Face](https://huggingface.co/datasets/Anthropic/EconomicIndex) — the upstream dataset.
- [Handa et al. (2025), arXiv:2503.04761](https://arxiv.org/abs/2503.04761) — the methodological source paper.
- [Tamkin et al. (2024), arXiv:2412.13678](https://arxiv.org/abs/2412.13678) — the Clio system paper.
- [Felten, Raj, and Seamans (2021)](https://doi.org/10.1002/smj.3286) — the AI Occupational Exposure (AIOE) measure that uses the same O*NET task taxonomy.
- [Acemoglu and Restrepo (2020)](https://doi.org/10.1086/705716) — the canonical automation-and-jobs paper that AEI's interaction-type framework references.
- [O*NET Database](https://www.onetonline.org/) — the U.S. Department of Labor's task taxonomy.
- [Standard Occupational Classification](https://www.bls.gov/soc/) — the U.S. Bureau of Labor Statistics' occupational classification system.
- [Anthropic Economic Futures](https://www.anthropic.com/economic-futures) — Anthropic's broader economic research programme.

## Citation

Please cite both the package and the underlying dataset.

```r
citation("aieconindex")
```

For the dataset specifically, `aei_cite()` returns ready-made strings:

```r
aei_cite("2025-09-15", format = "bibtex")
```

If you use the AEI in academic work, also cite [Handa et al. (2025), arXiv:2503.04761](https://arxiv.org/abs/2503.04761) — the methodological source paper. `aei_cite()` includes it by default.

## Contributing

Issues and pull requests welcome at https://github.com/charlescoverdale/aieconindex/issues. Useful contributions for v0.2 include:

- Occupational crosswalks (SOC ↔ ANZSCO ↔ ISCO ↔ SOC2010_UK)
- Joins to ONS Labour Force Survey, BLS OEWS, ABS Labour Force
- Replication helpers for specific Anthropic figures
- Vignettes demonstrating multi-release comparisons

For Anthropic-introduced schema changes that break `aei_index()` or `aei_geography()`, please open an issue with a sample of the new file structure (output of `aei_files(<new_release>)`).

## Licensing and attribution

This package is released under the [MIT License](LICENSE).

The underlying Anthropic Economic Index dataset is released by Anthropic under [Creative Commons Attribution 4.0 International (CC-BY-4.0)](https://creativecommons.org/licenses/by/4.0/). When using this package to retrieve or redistribute that data, attribution to Anthropic and to [Handa et al. (2025)](https://arxiv.org/abs/2503.04761) is required. Use `aei_cite()` for ready-made citation strings.

The bundled O*NET and SOC reference data (when accessed through the AEI) inherit their respective licences. See the [O*NET licensing page](https://www.onetonline.org/help/license) and the [SOC documentation](https://www.bls.gov/soc/).

This product uses the Anthropic Economic Index data but is not endorsed or certified by Anthropic.
