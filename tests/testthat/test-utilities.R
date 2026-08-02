test_that(".aei_resolve_release accepts the canonical id", {
  expect_equal(aieconindex:::.aei_resolve_release("release_2026_03_24"),
               "release_2026_03_24")
})

test_that(".aei_resolve_release accepts a date string", {
  expect_equal(aieconindex:::.aei_resolve_release("2026-03-24"),
               "release_2026_03_24")
})

test_that(".aei_resolve_release accepts an underscore-style date", {
  expect_equal(aieconindex:::.aei_resolve_release("2026_03_24"),
               "release_2026_03_24")
})

test_that(".aei_resolve_release returns the latest by date when asked", {
  latest <- aieconindex:::.aei_resolve_release("latest")
  expected <- aieconindex:::.aei_known_releases$release_id[
    which.max(aieconindex:::.aei_known_releases$release_date)
  ]
  expect_equal(latest, expected)
})

test_that(".aei_resolve_release errors on unknown release", {
  expect_error(aieconindex:::.aei_resolve_release("not_a_release"),
               regexp = "Could not resolve release")
})

test_that(".aei_resolve_url builds the expected raw URL", {
  url <- aieconindex:::.aei_resolve_url("release_2026_03_24",
                                        "data/aei_raw_claude_ai_2026-02-05_to_2026-02-12.csv")
  expect_match(url, "^https://huggingface.co/datasets/Anthropic/EconomicIndex/resolve/main/")
  expect_match(url, "release_2026_03_24/data/aei_raw_claude_ai")
})

test_that(".aei_format_bytes scales sensibly", {
  expect_equal(aieconindex:::.aei_format_bytes(0), "0 B")
  expect_equal(aieconindex:::.aei_format_bytes(512), "512 B")
  expect_match(aieconindex:::.aei_format_bytes(2048), "KB$")
  expect_match(aieconindex:::.aei_format_bytes(2 * 1024^2), "MB$")
  expect_match(aieconindex:::.aei_format_bytes(3 * 1024^3), "GB$")
})

test_that(".aei_release_id_date parses ids and returns NA otherwise", {
  expect_equal(aieconindex:::.aei_release_id_date("release_2026_06_26"),
               as.Date("2026-06-26"))
  expect_true(is.na(aieconindex:::.aei_release_id_date("labor_market_impacts")))
})

test_that(".aei_release_schema classifies the three epochs", {
  expect_equal(aieconindex:::.aei_release_schema("release_2025_02_10"), "wide")
  expect_equal(aieconindex:::.aei_release_schema("release_2025_03_27"), "wide")
  expect_equal(aieconindex:::.aei_release_schema("release_2025_09_15"), "long")
  expect_equal(aieconindex:::.aei_release_schema("release_2026_03_24"), "long")
  expect_equal(aieconindex:::.aei_release_schema("release_2026_06_26"), "monthly")
  expect_equal(aieconindex:::.aei_release_schema("release_2026_09_30"), "monthly")
  expect_equal(aieconindex:::.aei_release_schema("labor_market_impacts"), "unknown")
})

test_that(".aei_index_pattern matches the two filename conventions", {
  long_pat <- aieconindex:::.aei_index_pattern("long", "raw", "claude_ai")
  expect_true(grepl(long_pat, "data/aei_raw_claude_ai_2026-02-05_to_2026-02-12.csv"))
  expect_false(grepl(long_pat, "data/aei_claude_ai_2026-06-26.csv"))
  monthly_pat <- aieconindex:::.aei_index_pattern("monthly", "raw", "claude_ai")
  expect_true(grepl(monthly_pat, "data/aei_claude_ai_2026-06-26.csv"))
  expect_false(grepl(monthly_pat, "data/aei_raw_claude_ai_2026-02-05_to_2026-02-12.csv"))
  monthly_api <- aieconindex:::.aei_index_pattern("monthly", "raw", "1p_api")
  expect_true(grepl(monthly_api, "data/aei_1p_api_2026-06-26.csv"))
  expect_false(grepl(monthly_api, "data/aei_claude_ai_2026-06-26.csv"))
})

test_that(".aei_resolve_release resolves post-build releases via the live listing", {
  skip_on_cran()
  skip_if_offline()
  # Bypass the bundled table by pretending only the first release is known.
  releases <- aieconindex:::.aei_known_releases[1L, , drop = FALSE]
  expect_equal(
    aieconindex:::.aei_resolve_release("2026-06-26", releases = releases),
    "release_2026_06_26"
  )
  expect_equal(
    aieconindex:::.aei_resolve_release("release_2026_06_26", releases = releases),
    "release_2026_06_26"
  )
})
