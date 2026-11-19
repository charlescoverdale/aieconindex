test_that("a 404 on the listing reports the status, not a connection failure", {
  httr2::local_mocked_responses(function(req) httr2::response(status_code = 404L))
  err <- tryCatch(.aei_hf_list("no_such_release"), error = function(e) e)
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(msg, "404")
  expect_match(msg, "no_such_release", fixed = TRUE)
  expect_no_match(msg, "internet connection")
})

test_that("a 403 on the listing reports the status and URL", {
  httr2::local_mocked_responses(function(req) httr2::response(status_code = 403L))
  err <- tryCatch(.aei_hf_list("x"), error = function(e) e)
  expect_match(conditionMessage(err), "HTTP 403")
  expect_no_match(conditionMessage(err), "internet connection")
})

test_that("a 404 on a file download reports file not found and leaves no cache file", {
  cdir <- withr::local_tempdir()
  withr::local_options(aieconindex.cache_dir = cdir)
  httr2::local_mocked_responses(function(req) httr2::response(status_code = 404L))
  err <- tryCatch(
    .aei_fetch_file("release_2025_03_27", "missing.csv", quiet = TRUE),
    error = function(e) e
  )
  expect_match(conditionMessage(err), "File not found")
  expect_false(file.exists(file.path(cdir, "release_2025_03_27", "missing.csv")))
})

test_that("a transport failure keeps the connection message", {
  httr2::local_mocked_responses(function(req) stop("Could not resolve host"))
  err <- tryCatch(.aei_hf_list(""), error = function(e) e)
  expect_match(conditionMessage(err), "internet connection")
})
