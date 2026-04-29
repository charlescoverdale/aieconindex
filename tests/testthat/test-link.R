test_that("aei_link errors when x is not an aei_tbl", {
  expect_error(
    aei_link(data.frame(a = 1), data.frame(a = 1), by = "a"),
    regexp = "must be an aei_tbl"
  )
})

test_that("aei_link errors when y is not a data.frame", {
  x <- aieconindex:::new_aei_tbl(data.frame(a = 1:3))
  expect_error(aei_link(x, list(a = 1), by = "a"),
               regexp = "must be a data.frame")
})

test_that("aei_link errors when by is missing or empty", {
  x <- aieconindex:::new_aei_tbl(data.frame(a = 1:3))
  y <- data.frame(a = 1:3, z = 4:6)
  expect_error(aei_link(x, y, by = character(0)),
               regexp = "must name at least one")
})

test_that("aei_link errors when join column missing", {
  x <- aieconindex:::new_aei_tbl(data.frame(a = 1:3))
  y <- data.frame(b = 1:3)
  expect_error(aei_link(x, y, by = "a"), regexp = "Missing in")
})

test_that("aei_link returns an aei_tbl preserving provenance", {
  x <- aieconindex:::new_aei_tbl(
    data.frame(geo_id = c("GBR", "AUS", "USA"), value = 1:3),
    list(endpoint = "geography", release = "release_2025_09_15")
  )
  y <- data.frame(geo_id = c("GBR", "AUS"), gdp = c(48000, 65000))
  out <- aei_link(x, y, by = "geo_id", type = "left")
  expect_s3_class(out, "aei_tbl")
  expect_true("gdp" %in% names(out))
  expect_equal(nrow(out), 3L)  # left join keeps all x rows
  expect_true(is.na(out$gdp[out$geo_id == "USA"]))
  expect_equal(attr(out, "aei_query")$release, "release_2025_09_15")
})

test_that("aei_link supports inner join", {
  x <- aieconindex:::new_aei_tbl(data.frame(geo_id = c("GBR", "AUS", "USA"), value = 1:3))
  y <- data.frame(geo_id = c("GBR", "AUS"), gdp = c(48000, 65000))
  out <- aei_link(x, y, by = "geo_id", type = "inner")
  expect_equal(nrow(out), 2L)
})

test_that("aei_link supports renamed join keys", {
  x <- aieconindex:::new_aei_tbl(data.frame(cluster_name = c("a", "b"), value = 1:2))
  y <- data.frame(onet_id = c("a", "b"), aug_score = c(0.5, 0.7))
  out <- aei_link(x, y, by = c(cluster_name = "onet_id"), type = "left")
  expect_equal(nrow(out), 2L)
  expect_true("aug_score" %in% names(out))
})

test_that("aei_link warns when join produces zero rows", {
  x <- aieconindex:::new_aei_tbl(data.frame(geo_id = c("GBR", "AUS"), value = 1:2))
  y <- data.frame(geo_id = c("ZZZ"), gdp = 1)
  expect_warning(aei_link(x, y, by = "geo_id", type = "inner"),
                 regexp = "zero rows")
})
