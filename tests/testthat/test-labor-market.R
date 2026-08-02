test_that("aei_labor_market validates the table argument", {
  expect_error(aei_labor_market("not_a_table"),
               regexp = "should be one of")
})

test_that("aei_labor_market fetches the job exposure table (network)", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-lm"))
  on.exit(unlink(file.path(tempdir(), "aei-test-lm"), recursive = TRUE), add = TRUE)
  out <- aei_labor_market("job_exposure")
  expect_s3_class(out, "aei_tbl")
  expect_true(nrow(out) > 0L)
  q <- attr(out, "aei_query")
  expect_equal(q$endpoint, "labor_market")
  expect_equal(q$release, "labor_market_impacts")
})
