test_that("aei_index validates source and variant", {
  expect_error(aei_index("latest", source = "not_a_source"),
               regexp = "should be one of")
  expect_error(aei_index("latest", variant = "not_a_variant"),
               regexp = "should be one of")
})

test_that("aei_index errors informatively for an unknown release", {
  expect_error(aei_index("not_a_release"),
               regexp = "Could not resolve release")
})

test_that("aei_index returns an aei_tbl with expected provenance", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-index"))
  on.exit(unlink(file.path(tempdir(), "aei-test-index"), recursive = TRUE), add = TRUE)
  out <- aei_download("2025-03-27", "automation_vs_augmentation_v2.csv")
  expect_s3_class(out, "aei_tbl")
  expect_true(nrow(out) > 0L)
  q <- attr(out, "aei_query")
  expect_equal(q$endpoint, "download")
  expect_equal(q$release, "release_2025_03_27")
  expect_match(q$source_url,
               "^https://huggingface.co/datasets/Anthropic/EconomicIndex/resolve/main/release_2025_03_27/automation_vs_augmentation_v2\\.csv$")
})

test_that("automation_vs_augmentation_v2.csv has the expected schema and totals to 100", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-index2"))
  on.exit(unlink(file.path(tempdir(), "aei-test-index2"), recursive = TRUE), add = TRUE)
  out <- aei_download("2025-03-27", "automation_vs_augmentation_v2.csv")
  expect_true("interaction_type" %in% names(out))
  expect_true("pct" %in% names(out))
  expect_equal(nrow(out), 6L)
  expect_equal(sum(out$pct), 100, tolerance = 0.5)
})
