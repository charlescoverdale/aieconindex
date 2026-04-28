test_that("aei_download errors informatively for an unknown release", {
  expect_error(aei_download("not_a_release", "anything.csv"),
               regexp = "Could not resolve release")
})

test_that("aei_download returns an aei_tbl for CSV files", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-dl1"))
  on.exit(unlink(file.path(tempdir(), "aei-test-dl1"), recursive = TRUE), add = TRUE)
  out <- aei_download("2025-03-27", "automation_vs_augmentation_v2.csv")
  expect_s3_class(out, "aei_tbl")
  expect_s3_class(out, "data.frame")
  expect_true(nrow(out) > 0L)
})

test_that("aei_download returns a list for JSON files", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-dl2"))
  on.exit(unlink(file.path(tempdir(), "aei-test-dl2"), recursive = TRUE), add = TRUE)
  out <- aei_download("2025-09-15",
                      "data/output/request_hierarchy_tree_claude_ai.json")
  expect_type(out, "list")
  expect_true(length(out) > 0L)
})

test_that("aei_download returns a local path for unrecognised extensions", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-dl3"))
  on.exit(unlink(file.path(tempdir(), "aei-test-dl3"), recursive = TRUE), add = TRUE)
  out <- aei_download("2025-03-27",
                      "automation_augmentation_comparison.png")
  expect_type(out, "character")
  expect_true(file.exists(out))
})

test_that("aei_download raises an informative error on a 404", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-dl4"))
  on.exit(unlink(file.path(tempdir(), "aei-test-dl4"), recursive = TRUE), add = TRUE)
  expect_error(aei_download("2025-03-27", "definitely_does_not_exist.csv"),
               regexp = "(File not found|HTTP)")
})
