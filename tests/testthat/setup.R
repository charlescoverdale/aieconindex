# Belt-and-suspenders: redirect the package cache to a per-test
# temporary directory so that tests cannot write to the user's home
# filespace, even if a test forgets to set the option locally.
# CRAN policy hard rule.
options(aieconindex.cache_dir = file.path(tempdir(), "aieconindex-tests"))
