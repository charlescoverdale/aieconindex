test_that("aei_clusters validates source", {
  expect_error(aei_clusters("2025-09-15", source = "not_a_source"),
               regexp = "should be one of")
})

test_that("aei_clusters errors informatively for releases without clusters", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-cl1"))
  on.exit(unlink(file.path(tempdir(), "aei-test-cl1"), recursive = TRUE), add = TRUE)
  expect_error(aei_clusters("2025-02-10"),
               regexp = "No request_hierarchy_tree_")
})

test_that("aei_clusters returns a non-empty list for releases with clusters", {
  skip_on_cran()
  skip_if_offline()
  withr::local_options(aieconindex.cache_dir = file.path(tempdir(), "aei-test-cl2"))
  on.exit(unlink(file.path(tempdir(), "aei-test-cl2"), recursive = TRUE), add = TRUE)
  out <- aei_clusters("2025-09-15", source = "claude_ai")
  expect_type(out, "list")
  expect_true(length(out) > 0L)
})
