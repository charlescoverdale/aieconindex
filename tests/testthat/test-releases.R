test_that("aei_releases works offline (live = FALSE)", {
  out <- aei_releases(live = FALSE)
  expect_s3_class(out, "aei_tbl")
  expect_true(all(c("release_id", "release_date", "model", "notes") %in% names(out)))
  expect_true(nrow(out) >= 5L)
})

test_that("aei_releases live call works when network is available", {
  skip_on_cran()
  skip_if_offline()
  out <- aei_releases(live = TRUE)
  expect_s3_class(out, "aei_tbl")
  expect_true("release_id" %in% names(out))
  expect_true(nrow(out) >= 5L)
})

test_that("aei_files lists files for a known release when network is available", {
  skip_on_cran()
  skip_if_offline()
  out <- aei_files("2025-03-27", recursive = FALSE)
  expect_s3_class(out, "aei_tbl")
  expect_true("path" %in% names(out))
  expect_true(any(grepl("README\\.md$", out$path)))
})
