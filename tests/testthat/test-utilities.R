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
