test_that("aei_tasks errors informatively for releases without the standalone file", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-tk1"))
  on.exit(unlink(file.path(tempdir(), "aei-test-tk1"), recursive = TRUE), add = TRUE)
  expect_error(aei_tasks("2026-01-15"),
               regexp = "No onet_task_statements")
})

test_that("aei_tasks returns the bundled task statements for 2025-03-27", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-tk2"))
  on.exit(unlink(file.path(tempdir(), "aei-test-tk2"), recursive = TRUE), add = TRUE)
  out <- aei_tasks("2025-03-27")
  expect_s3_class(out, "aei_tbl")
  expect_true(nrow(out) > 100L)
  q <- attr(out, "aei_query")
  expect_equal(q$endpoint, "tasks")
  expect_equal(q$release, "release_2025_03_27")
})
