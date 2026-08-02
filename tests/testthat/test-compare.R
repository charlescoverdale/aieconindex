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

test_that(".aei_compare_by picks keys from the shared schema", {
  long_cols <- c("cluster_name", "facet", "variable", "value")
  monthly_cols <- c("date_start", "date_end", "geo_id", "geo_level",
                    "category_name", "hierarchy_level", "metric_id",
                    "node_name", "value")
  expect_equal(aieconindex:::.aei_compare_by(long_cols, long_cols),
               c("cluster_name", "facet", "variable"))
  expect_equal(aieconindex:::.aei_compare_by(monthly_cols, monthly_cols),
               c("geo_id", "geo_level", "category_name",
                 "hierarchy_level", "metric_id", "node_name"))
  expect_error(aieconindex:::.aei_compare_by(long_cols, monthly_cols),
               regexp = "default join keys")
})

test_that(".aei_latest_window keeps only the most recent date window", {
  df <- data.frame(
    date_start = c("2026-04-01", "2026-05-01", "2026-05-01"),
    value = 1:3,
    stringsAsFactors = FALSE
  )
  expect_message(out <- aieconindex:::.aei_latest_window(df, "release_x"),
                 regexp = "multiple date windows")
  expect_equal(out$value, 2:3)
  # Tables without date_start pass through untouched
  df2 <- data.frame(value = 1:3)
  expect_identical(aieconindex:::.aei_latest_window(df2), df2)
  # Single-window tables pass through silently
  df3 <- data.frame(date_start = rep("2026-05-01", 3), value = 1:3,
                    stringsAsFactors = FALSE)
  expect_silent(out3 <- aieconindex:::.aei_latest_window(df3))
  expect_equal(nrow(out3), 3L)
})
