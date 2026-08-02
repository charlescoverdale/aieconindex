test_that("aei_concentration computes HHI correctly for known cases", {
  # Three equal shares of 1/3 each
  out <- aei_concentration(data.frame(value = c(1/3, 1/3, 1/3)))
  expect_equal(out$n, 3L)
  expect_equal(out$hhi, 3 * (1/3)^2, tolerance = 1e-10)

  # Single dominant share
  out2 <- aei_concentration(data.frame(value = c(1, 0, 0)))
  expect_equal(out2$n, 1L)
  expect_equal(out2$hhi, 1, tolerance = 1e-10)

  # Two equal shares
  out3 <- aei_concentration(data.frame(value = c(0.5, 0.5)))
  expect_equal(out3$hhi, 0.5, tolerance = 1e-10)
})

test_that("aei_concentration computes CR_n correctly", {
  out <- aei_concentration(
    data.frame(value = c(40, 30, 20, 5, 3, 2)),
    top_n = 4L
  )
  expect_equal(out$cr_4, 95)  # top 4 shares: 40 + 30 + 20 + 5
})

test_that("aei_concentration entropy is bounded by log2(n)", {
  out <- aei_concentration(data.frame(value = c(0.25, 0.25, 0.25, 0.25)))
  expect_equal(out$entropy_bits, 2, tolerance = 1e-10)         # log2(4)
  expect_equal(out$entropy_max_bits, 2, tolerance = 1e-10)
  expect_equal(out$entropy_normalised, 1, tolerance = 1e-10)
})

test_that("aei_concentration entropy is zero for a single dominant share", {
  out <- aei_concentration(data.frame(value = c(1, 0, 0, 0)))
  expect_equal(out$entropy_bits, 0, tolerance = 1e-10)
  expect_true(is.na(out$entropy_normalised) || out$entropy_normalised == 0)
})

test_that("aei_concentration drops NA, zero, and negative shares", {
  out <- aei_concentration(data.frame(value = c(0.5, NA, 0, -0.1, 0.5)))
  expect_equal(out$n, 2L)
  expect_equal(out$hhi, 0.5, tolerance = 1e-10)
})

test_that("aei_concentration auto-detects share column", {
  out_value <- aei_concentration(data.frame(value = c(50, 30, 20)))
  out_pct   <- aei_concentration(data.frame(pct = c(50, 30, 20)))
  expect_equal(out_value$hhi, out_pct$hhi)
})

test_that("aei_concentration errors when no share column found", {
  expect_error(aei_concentration(data.frame(other = 1:3)),
               regexp = "Could not find a share column")
})

test_that("aei_concentration supports group_cols", {
  df <- data.frame(
    facet = c("a", "a", "a", "b", "b"),
    value = c(0.5, 0.3, 0.2, 0.7, 0.3)
  )
  out <- aei_concentration(df, group_cols = "facet")
  expect_equal(nrow(out), 2L)
  expect_true("facet" %in% names(out))
  # HHI for facet "b" = 0.49 + 0.09 = 0.58
  expect_equal(out$hhi[out$facet == "b"], 0.58, tolerance = 1e-10)
})

test_that("aei_concentration handles all-zero shares without error", {
  out <- aei_concentration(data.frame(value = c(0, 0, 0)))
  expect_equal(out$n, 0L)
  expect_true(is.na(out$hhi))
})

test_that("aei_concentration rescale normalises shares before HHI and CR", {
  # Two equal shares that sum to 40: raw HHI is 800, rescaled 5000.
  df <- data.frame(value = c(20, 20))
  raw <- aei_concentration(df, top_n = 1L)
  expect_equal(raw$hhi, 800)
  expect_equal(raw$cr_1, 20)
  scaled <- aei_concentration(df, top_n = 1L, rescale = TRUE)
  expect_equal(scaled$hhi, 5000)
  expect_equal(scaled$cr_1, 50)
  # Entropy is scale-invariant
  expect_equal(raw$entropy_bits, scaled$entropy_bits)
})
