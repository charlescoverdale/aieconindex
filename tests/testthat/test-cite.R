test_that("aei_cite returns a text citation by default", {
  out <- aei_cite()
  expect_type(out, "character")
  expect_true(grepl("Anthropic", out))
  expect_true(grepl("CC-BY", out))
})

test_that("aei_cite includes Handa et al. by default and omits when method = FALSE", {
  with_method <- aei_cite("2026-03-24", format = "text", method = TRUE)
  expect_match(with_method, "Handa")
  expect_match(with_method, "2503\\.04761")
  no_method <- aei_cite("2026-03-24", format = "text", method = FALSE)
  expect_false(grepl("Handa", no_method))
})

test_that("aei_cite returns a BibTeX entry when asked", {
  out <- aei_cite("2026-03-24", format = "bibtex")
  expect_match(out, "@misc")
  expect_match(out, "release_2026_03_24")
  expect_match(out, "url = ")
  expect_match(out, "handa2025economic")
})

test_that("aei_cite returns a bibentry object when asked, possibly multiple", {
  out <- aei_cite(format = "bibentry")
  expect_s3_class(out, "bibentry")
  expect_true(length(out) >= 2L)
})

test_that("aei_cite includes the report URL when one is bundled", {
  out <- aei_cite("2025-09-15", format = "bibtex")
  expect_match(out, "Report:")
  expect_match(out, "Economic-Index\\.pdf")
})

test_that("aei_cite errors on unknown release", {
  expect_error(aei_cite("not_a_release", format = "text"),
               regexp = "Could not resolve release")
})
