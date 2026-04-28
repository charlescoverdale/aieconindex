test_that("aei_cache_dir respects the option override", {
  withr::with_options(list(aieconindex.cache_dir = tempdir()), {
    expect_equal(normalizePath(aei_cache_dir(), mustWork = FALSE),
                 normalizePath(tempdir(), mustWork = FALSE))
  })
})

test_that("aei_cache_info returns the empty shape when cache is missing", {
  td <- file.path(tempdir(), "aieconindex-empty-test")
  unlink(td, recursive = TRUE)
  withr::with_options(list(aieconindex.cache_dir = td), {
    info <- aei_cache_info()
    expect_equal(info$n_files, 0L)
    expect_equal(info$size_bytes, 0)
    expect_s3_class(info$files, "data.frame")
    expect_equal(nrow(info$files), 0L)
  })
})

test_that("aei_cache_info reports files when present", {
  td <- file.path(tempdir(), "aieconindex-populated-test")
  unlink(td, recursive = TRUE)
  dir.create(td, recursive = TRUE, showWarnings = FALSE)
  writeLines("hello", file.path(td, "a.txt"))
  writeLines("world world", file.path(td, "b.txt"))
  withr::with_options(list(aieconindex.cache_dir = td), {
    info <- aei_cache_info()
    expect_equal(info$n_files, 2L)
    expect_true(info$size_bytes > 0)
    expect_s3_class(info$files, "data.frame")
  })
  unlink(td, recursive = TRUE)
})

test_that("aei_cache_clear removes files from the cache", {
  td <- file.path(tempdir(), "aieconindex-clear-test")
  unlink(td, recursive = TRUE)
  dir.create(td, recursive = TRUE, showWarnings = FALSE)
  writeLines("x", file.path(td, "a.txt"))
  withr::with_options(list(aieconindex.cache_dir = td), {
    expect_equal(aei_cache_info()$n_files, 1L)
    aei_cache_clear()
    expect_equal(aei_cache_info()$n_files, 0L)
  })
  unlink(td, recursive = TRUE)
})
