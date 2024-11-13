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

.generate_raster <- function(x, varname) {
  bgn <- .bluelink_generator(x, varname = varname)
  switch(.Platform$OS.type,
    unix =   terra::rast(.bluelink_fileserver(bgn), vsi = TRUE),
    windows = terra::rast(raster::brick(.bluelink_dods(bgn)), vsi = TRUE))

}

#' Read Mixed Layer Depth
#'
#' @param x date or datetime object or string
#'
#' @return SpatRaster
#' @export
#'
#' @examples
#' a <- read_mld()
#' b <- read_mld("2023-12-31")
#' ex <- terra::ext(14, 200, -70, -40)
#' #terra::crop(a, ex) - terra::crop(b, ex)
read_mld <- function(x) {
  mindate <- as.Date("1993-01-01")
  if (missing(x)) x <- mindate
  x <- as.Date(x)[1]



  obj <- .generate_raster(x, varname = "ocean_mld")
  ## check here
  stopifnot(terra::nlyr(obj) == lubridate::days_in_month(x[1]))
  obj[[as.integer(format(x, "%d"))]]

}


#' Title
#'
#' @param x date or datetime object or string
#' @param varname variable name one of "ocean_<s>" salt, temp, u, v, w  (being salt=salinity, temp=temperature, u,v,w= velocity components in x,y,z direction)
#' @param depth
#'
#' @return SpatRaster
#' @export
#'
#' @examples
#' read_bluelink(varname = "ocean_w")
#' read_bluelink("2023-01-05", "ocean_salt")
read_bluelink <- function(x, varname = c("ocean_salt", "ocean_temp",
                                     "ocean_u", "ocean_v", "ocean_w"), depth = 1L) {
  mindate <- as.Date("1993-01-01")
  if (varname == "ocean_w")mindate <- as.Date("1998-01-01") ## FIXME: I don't know why

  if (missing(x)) x <- mindate
  x <- as.Date(x)[1]
  depth <- depth[1L]
  if (length(depth) < 1 || depth < 1 || depth > 51 || is.na(depth)) stop("only 51 depths available")
  varname <- match.arg(varname)
  obj <- .generate_raster(x, varname = varname)

  stopifnot(terra::nlyr(obj) == (lubridate::days_in_month(x[1]) * 51))
  intday <- as.integer(format(x, "%d"))
  obj[[(intday-1) * 51 + depth ]]
}

