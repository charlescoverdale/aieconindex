test_that("new_aei_tbl wraps a data frame and adds attributes", {
  df <- data.frame(a = 1:3, b = letters[1:3], stringsAsFactors = FALSE)
  out <- aieconindex:::new_aei_tbl(df, list(endpoint = "test", release = "release_2025_02_10"))
  expect_s3_class(out, "aei_tbl")
  expect_s3_class(out, "data.frame")
  expect_equal(attr(out, "aei_query")$endpoint, "test")
  expect_equal(attr(out, "aei_query")$release, "release_2025_02_10")
})

test_that("print.aei_tbl emits a header", {
  df <- data.frame(a = 1, b = 2)
  out <- aieconindex:::new_aei_tbl(df, list(endpoint = "test", release = "rel"))
  msg <- capture.output(print(out))
  expect_true(any(grepl("# AEI:", msg)))
  expect_true(any(grepl("endpoint = test|test", msg) | grepl("test", msg)))
})

test_that("summary.aei_tbl emits a query summary", {
  df <- data.frame(a = 1:2)
  out <- aieconindex:::new_aei_tbl(df, list(endpoint = "test", release = "rel"))
  msg <- capture.output(summary(out))
  expect_true(any(grepl("AEI query summary", msg)))
  expect_true(any(grepl("rows: 2", msg)))
})

test_that("subsetting preserves the aei_tbl class and attributes", {
  df <- data.frame(a = 1:3, b = letters[1:3], stringsAsFactors = FALSE)
  out <- aieconindex:::new_aei_tbl(df, list(endpoint = "test", release = "rel"))
  sub_rows <- out[1:2, ]
  expect_s3_class(sub_rows, "aei_tbl")
  expect_equal(attr(sub_rows, "aei_query")$endpoint, "test")

  sub_cols <- out[, "a", drop = FALSE]
  expect_s3_class(sub_cols, "aei_tbl")
  expect_equal(nrow(sub_cols), 3L)
})
