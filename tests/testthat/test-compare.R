test_that("aei_compare validates source and variant", {
  expect_error(aei_compare("2025-09-15", "2026-03-24", source = "not_a_source"),
               regexp = "should be one of")
  expect_error(aei_compare("2025-09-15", "2026-03-24", variant = "not_a_variant"),
               regexp = "should be one of")
})

test_that("aei_compare errors when comparing a release with itself", {
  expect_error(aei_compare("2025-09-15", "2025-09-15"),
               regexp = "compare a release with itself")
})

test_that("aei_compare errors informatively on unknown release", {
  expect_error(aei_compare("not_a_release", "2025-09-15"),
               regexp = "Could not resolve release")
})

test_that("aei_compare flags schema mismatches informatively (network)", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-cmp2"))
  on.exit(unlink(file.path(tempdir(), "aei-test-cmp2"), recursive = TRUE), add = TRUE)
  # Wide-format 2025-03-27 has no `cluster_name` / `facet` / `variable` columns
  expect_error(
    aei_compare("2025-03-27", "2025-09-15"),
    regexp = "(Join keys not present|No.*CSV found|cannot be compared)"
  )
})
