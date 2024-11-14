test_that("access works", {
  skip_if_not(requireNamespace("curl", quietly = TRUE))
  skip_if_offline()
  skip_on_cran()
  r <- read_mld()
  r2 <- read_mld("2023-12-31")
  expect_true(inherits(r, "SpatRaster"))
  expect_equal(terra::nlyr(r), 1L)
  expect_equal(as.Date(terra::time(r2)), as.Date(as.POSIXct("2023-12-31", tz = "UTC")))
  a <- terra::crop(r, terra::ext(100, 101, -50, -49))
  v <- terra::values(a)
  expect_true(!anyNA(v))
  expect_true(min(v) > 12)
  expect_true(max(v) > 19)

  expect_true(terra::extract(r, cbind(147, -48)) <
  terra::extract(r2, cbind(147, -48)))

  r <- read_bluelink(varname = "ocean_temp")
  expect_true(inherits(r, "SpatRaster"))
  expect_equal(terra::nlyr(r), 1L)

  a <- terra::crop(r, terra::ext(100, 101, -50, -49))

terra::depth(a)
})
