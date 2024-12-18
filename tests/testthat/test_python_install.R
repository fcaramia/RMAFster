context("pysam installed")

test_that("check for pysam installation", {

  pysam <- reticulate::import("pysam")
  expect_equal(is.null(pysam),F)

})
