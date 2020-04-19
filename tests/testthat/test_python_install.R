context("Python3 and pysam installed")

test_that("check for Python3 installation", {

  expect_equal(reticulate::use_python('/usr/local/bin/python3',required = T),"/usr/local/bin/python3")

})

test_that("check for pysam installation", {

  reticulate::use_python('/usr/local/bin/python3',required = T)
  pysam <- reticulate::import("pysam")
  expect_equal(is.null(pysam),F)

})
