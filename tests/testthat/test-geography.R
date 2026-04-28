test_that("aei_geography validates source and geography", {
  expect_error(aei_geography("2025-09-15", source = "not_a_source"),
               regexp = "should be one of")
  expect_error(aei_geography("2025-09-15", geography = "not_a_geography"),
               regexp = "should be one of")
})

test_that("aei_geography errors informatively for pre-geographic releases", {
  expect_error(aei_geography("2025-02-10"),
               regexp = "does not contain geographic data")
  expect_error(aei_geography("2025-03-27"),
               regexp = "does not contain geographic data")
})

test_that("aei_geography returns rows for a known country in 2025-09-15", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-geo1"))
  on.exit(unlink(file.path(tempdir(), "aei-test-geo1"), recursive = TRUE), add = TRUE)
  out <- aei_geography("2025-09-15", country = "GBR")
  expect_s3_class(out, "aei_tbl")
  expect_true(nrow(out) > 0L)
  expect_true(all(toupper(out$geo_id) == "GBR"))
  expect_true(all(out$geography == "country"))
})

test_that("aei_geography returns US-state rows when geography = state_us", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-geo2"))
  on.exit(unlink(file.path(tempdir(), "aei-test-geo2"), recursive = TRUE), add = TRUE)
  out <- aei_geography("2025-09-15", geography = "state_us")
  expect_s3_class(out, "aei_tbl")
  expect_true(nrow(out) > 0L)
  expect_true(all(out$geography == "state_us"))
})
