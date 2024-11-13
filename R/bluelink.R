.make_daily <- function(x, date) {
  sprintf("daily/%s_%s.nc", x, format(date, "%Y_%m"))
}
.make_month <- function(x, date) {
  sprintf("month/%s_mth_%s.nc", x, format(date, "%Y_%m"))
}

.make_annual <- function(x, date) {
  sprintf("annual/%s_ann_%s.nc", x, format(date, "%Y"))
}
.bluelink_generator <- function(date, time.resolution = c("daily", "month", "annual"),
                                varname = c("atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force",
                                            "ocean_mld", "ocean_salt", "ocean_temp", "ocean_tx_trans_int_z",
                                            "ocean_ty_trans_int_z", "ocean_u", "ocean_v", "ocean_w")) {
  time.resolution <- match.arg(time.resolution)
  varname <- match.arg(varname)
  date <- as.Date(date)[1]
  if (length(date) < 1 ||anyNA(date)) stop("bad date input")
  switch(time.resolution,
                               daily = .make_daily(varname, date),
                               month = .make_month(varname, date),
                               annual = .make_annual(varname, date))
}

.bluelink_fileserver <- function(x) {
  sprintf("https://thredds.nci.org.au/thredds/fileServer/gb6/BRAN/BRAN2020/%s", x)
}

.bluelink_dods <- function(x) {
  sprintf("https://thredds.nci.org.au/thredds/dodsC/gb6/BRAN/BRAN2020/%s", x)
}

# c("ocean_mld", "ocean_salt", "ocean_temp", "ocean_tx_trans_int_z",
#   "ocean_u", "ocean_v", "ocean_w")

.do_raster <- function(x, band,  depth) {
  requireNamespace("ncdf4", quietly = TRUE);
  out <- terra::rast(raster::raster(.bluelink_dods(x), band = band, level = depth) * 1)
  terra::crs(out) <- "EPSG:4326"
  out
}
.do_terra <- function(x, band, depth) {
  idx <- (depth-1) * 51 + band

  terra::rast(.bluelink_fileserver(x), vsi = TRUE)[[idx]]
}
.generate_raster <- function(x, varname, band, depth) {
  bgn <- .bluelink_generator(x, varname = varname)
  switch(.Platform$OS.type,
    unix =   .do_terra(bgn, band, depth),
    windows = .do_raster(bgn, band, depth))

}

#' Read Mixed Layer Depth
#'
#' @param x date or datetime object or string
#' @param ... passed to [read_bluelink()]
#' @return SpatRaster
#' @export
#'
#' @examples
#' a <- read_mld()
#' b <- read_mld("2023-12-31")
#' ex <- terra::ext(14, 200, -70, -40)
#' #terra::crop(a, ex) - terra::crop(b, ex)
read_mld <- function(x,  ...) {
 read_bluelink(x, varname = "ocean_mld", depth = 1L, ...)
}


#' Title
#'
#' The 'depth' argument is from 1 to 51.
#' Time is 'days since 1979-01-01 00:00:00'
#' See a representative ncdump output in examples, text saved in this package.
#' @param x date or datetime object or string
#' @param varname variable name one of "ocean_<s>" salt, temp, u, v, w  (being salt=salinity, temp=temperature, u,v,w= velocity components in x,y,z direction)
#' @param depth depth level (there are 51, from the surface to the bottom) see Details
#'
#' @return SpatRaster
#' @export
#'
#' @examples
#' read_bluelink(varname = "ocean_w")
#' read_bluelink("2023-01-05", "ocean_salt")
#' if(interactive()) {
#'  sfile <- "ncdump/atm_flux_diag_1993_01.nc.dump"
#'  sfile1 <- system.file(sfile, package = "bluelink", mustWork = TRUE)
#'  utils::browseURL(sfile1)
#' }
read_bluelink <- function(x, varname = c("ocean_salt", "ocean_temp",
                                     "ocean_u", "ocean_v", "ocean_w", "ocean_mld"), depth = 1L) {
  mindate <- as.Date("1993-01-01")
  varname <- match.arg(varname)
  if (varname == "ocean_w") mindate <- as.Date("1998-01-01") ## FIXME: I don't know why
  if (varname == "ocean_mld") depth <- 1L  ##FIXME: warn/message on this

  if (missing(x)) x <- mindate
  x <- as.Date(x)[1]
  depth <- depth[1L]
  band <- as.integer(format(x, "%d"))

  if (length(depth) < 1 || depth < 1 || depth > 51 || is.na(depth)) stop("only 51 depths available")

  out <- .generate_raster(x, varname = varname, band = band,  depth = depth)
  terra::ext(out) <- terra::ext(round(as.vector(terra::ext(out))))
  out
}

