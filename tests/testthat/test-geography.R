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

test_that(".aei_geography_filter handles the long schema", {
  df <- data.frame(
    geography = c("global", "country", "country", "state_us"),
    geo_id = c("GLOBAL", "GBR", "AUS", "CA"),
    value = 1:4,
    stringsAsFactors = FALSE
  )
  out <- aieconindex:::.aei_geography_filter(df, "country", NULL)
  expect_equal(out$geo_id, c("GBR", "AUS"))
  out <- aieconindex:::.aei_geography_filter(df, "country", "gbr")
  expect_equal(out$geo_id, "GBR")
  out <- aieconindex:::.aei_geography_filter(df, "state_us", NULL)
  expect_equal(out$geo_id, "CA")
  expect_error(aieconindex:::.aei_geography_filter(df, "subregion", NULL),
               regexp = "predates")
})

test_that(".aei_geography_filter handles the monthly schema", {
  df <- data.frame(
    geo_level = c("global", "country", "country", "subregion", "subregion"),
    geo_id = c("GLOBAL", "GBR", "USA", "US-CA", "GB-ENG"),
    value = 1:5,
    stringsAsFactors = FALSE
  )
  out <- aieconindex:::.aei_geography_filter(df, "country", NULL)
  expect_equal(out$geo_id, c("GBR", "USA"))
  out <- aieconindex:::.aei_geography_filter(df, "state_us", NULL)
  expect_equal(out$geo_id, "US-CA")
  out <- aieconindex:::.aei_geography_filter(df, "subregion", NULL)
  expect_equal(out$geo_id, c("US-CA", "GB-ENG"))
  out <- aieconindex:::.aei_geography_filter(df, "country", "GBR")
  expect_equal(out$geo_id, "GBR")
})

test_that(".aei_geography_filter errors when no geographic column exists", {
  df <- data.frame(a = 1)
  expect_error(aieconindex:::.aei_geography_filter(df, "country", NULL),
               regexp = "geo_level")
})
