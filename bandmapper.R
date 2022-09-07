library(whatarelief)
library(ximage)


temp <- readRDS("inst/extdata/ocean_temp.rds")

bransst <- function(date = NULL) {
  if (is.null(date)) date <- max(temp$date)
  i <- findInterval(as.POSIXct(date), temp$date)
  src <- temp$dsn[i]
  band <- temp$bandstart[i]
  vapour::vapour_vrt(src, bands = band, projection = "OGC:CRS84", sds = 2)
}

info0 <- vapour::vapour_raster_info(temp$dsn[1])
ex0 <- c(-75, -50, 63, 75) + c(360, 360, 0, 0)
qu <- vaster::vcrop(ex0, info0$extent, info0$dimension)
ex <- qu$extent
dm <- qu$dimension
i <- i + 1
  vrt <- bransst(temp$date[i])
  sst <- elevation(source = vrt, extent = ex, dimension = dm)
ximage(sst, extent = ex)



## we have every file, user needs set of variables and range of dates
available_bran <- function(x) {  ## x is allbran from data_raw

}
variables_bran <- function(x) {
  str_extract(basename(x$fileurl), ".+(?=_)")
}
.bandmapper <- function(x, varname = NULL) {
  x <- RNetCDF::open.nc(x)
  meta <- ncmeta::nc_meta(x)
  if (is.null(varname)) {
    vars <- meta$variable
    varname <- vars$name[which.max(vars$ndims)]
  }
  ax <- ncmeta::nc_axes(x, varname)
  dims <-   ax$dimension[order(ax$axis)]
  dim_names <- meta$dimension$name[match(dims, meta$dimension$id)]
  lapply(dim_names, function(.x) RNetCDF::var.get.nc(x, .x))




}
