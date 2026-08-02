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

test_that("the monthly filename pattern matches the 2026-06-26 release files (network)", {
  skip_on_cran()
  skip_if_offline()
  files <- aei_files("2026-06-26", recursive = TRUE)
  pat_ai <- aieconindex:::.aei_index_pattern("monthly", "raw", "claude_ai")
  pat_api <- aieconindex:::.aei_index_pattern("monthly", "raw", "1p_api")
  expect_true(any(grepl(pat_ai, files$path[files$type == "file"])))
  expect_true(any(grepl(pat_api, files$path[files$type == "file"])))
})
