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

.fibrebase <- function(source, version = NULL) {
  if (is.null(version)) {
    version <- getOption("bluelink.BRANVERSION")
  }
  sprintf("https://thredds.nci.org.au/thredds/%s/gb6/BRAN/%s", source, version)
}
.bluelink_fileserver <- function(x) {
  sprintf("%s/%s", .fibrebase("fileServer"), x)
}

.bluelink_dods <- function(x) {
  sprintf("%s/%s", .fibrebase("dodsC"), x)
}

# c("ocean_mld", "ocean_salt", "ocean_temp", "ocean_tx_trans_int_z",
#   "ocean_u", "ocean_v", "ocean_w")

.epoch <- ISOdatetime(1979, 1, 1, 0, 0, 0, tz = "UTC")
.do_raster <- function(x, band,  level) {
  requireNamespace("ncdf4", quietly = TRUE);
  dsn <- .bluelink_dods(x)
  ht <- suppressMessages(tidync::hyper_transforms(tidync::tidync(dsn)))
  out <- terra::rast(raster::raster(dsn, band = band, level = level) * 1)

  if (!is.null(ht$Time$Time)) {
    tv <- ht$Time$Time[band]
    terra::time(out) <- .epoch + as.numeric(tv) * 24 * 3600
  }
  if (!is.null(ht$st_ocean$st_ocean)) {
    sv <- ht$st_ocean$st_ocean[level]
    terra::depth(out) <- sv
  } else {
    terra::depth(out) <- 2.5
  }
  terra::crs(out) <- "EPSG:4326"
  out
}


#' Generate a description of a bluelink file for GDAL
#'
#' @param x date string or date(time) format
#' @param varname name of variable (that identifies the file)
#' @param vsicurl include the prefix (default TRUE)
#' @return string to a thredds file that GDAL can open
#' @export
#'
#' @examples
#' bluelink_dsn()
#' bluelink_dsn("2020-01-01", varname = "ocean_u")
#' bluelink_dsn("1993-01-01")
bluelink_dsn <- function(x, varname = c("atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force",
                                         "ocean_mld", "ocean_salt", "ocean_temp", "ocean_tx_trans_int_z",
                                         "ocean_ty_trans_int_z", "ocean_u", "ocean_v", "ocean_w"), vsicurl = TRUE) {
  if (missing(x)) x <- "2024-06-30"

  if (as.Date(x) < as.Date("2010-01-01") && getOption("bluelink.BRANVERSION") == "BRAN2023") {
    options("bluelink.BRANVERSION" = "BRAN2020")
    on.exit(Sys.setenv("bluelink.BRANVERSION" = "BRAN2023"))
  }
  bgn <- .bluelink_generator(x, varname = varname)
  out <- .bluelink_fileserver(bgn)
  if (vsicurl) {
    out <- sprintf("/vsicurl/%s", out)
  }
  out
}
.do_terra <- function(x, band, level) {

  dsn <- .bluelink_fileserver(x)
  out <- terra::rast(dsn, vsi = TRUE)
  nl <- 51
  if (terra::nlyr(out) < 50) nl <- 1
  idx <- level + (band-1) * nl
  out <- out[[idx]]
  si <- gregexpr("st_ocean=", names(out)[1])
  if (si[[1]] > 0) {
    sv <- strsplit(strsplit(names(out), "st_ocean=")[[1]][[2]], "_")[[1]][[1]]
    terra::depth(out) <- as.numeric(sv)
    #print(sv)
  } else {
    terra::depth(out) <- 2.5
  }
  ti <- gregexpr("Time=", names(out)[1])
  if (ti[[1]] > 0) {
    tv <- strsplit(strsplit(names(out), "Time=")[[1]][[2]], "_")[[1]][[1]]
    terra::time(out) <- .epoch + as.numeric(tv) * 24 * 3600
  }
  out
}
.generate_raster <- function(x, varname, band, level) {
  bgn <- .bluelink_generator(x, varname = varname)
  switch(.Platform$OS.type,
    unix =   .do_terra(bgn, band, level),
    windows = .do_raster(bgn, band, level))

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
 read_bluelink(x, varname = "ocean_mld", level = 1L, ...)
}


#' Title
#'
#' The 'level' argument is from 1 to 51, use 'terra::depth(x)' to disover the value.
#' Time is 'days since 1979-01-01 00:00:00'
#' See a representative ncdump output in examples, text saved in this package.
#'
#' We can't quite support these collections:  "atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force", because they each have multiple variables.
#' Thinking about it ..., we probably need a function for each variable to make it work.

#' @param x date or datetime object or string
#' @param varname variable name one of "ocean_<s>" salt, temp, u, v, w  (being salt=salinity, temp=temperature, u,v,w= velocity components in x,y,z direction)
#' @param level depth level (a value between 1 and 51, from the surface to the bottom) see Details
#' @param ... unused currently
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
                                     "ocean_u", "ocean_v", "ocean_w", "ocean_mld"), level = 1L, ...) {
  mindate <- as.Date("2010-01-01")
  ## WIP we need to handle different start and end date availability for older stuff
  if (getOption("bluelink.BRANVERSION") == "BRAN2020") {
    mindate <- "1993-01-01"
    if (varname == "ocean_w") mindate <- as.Date("1998-01-01")
  }
  if (missing(x)) x <- mindate
  if (x < as.Date("2010-01-01") && getOption("bluelink.BRANVERSION") == "BRAN2023") {
    options("bluelink.BRANVERSION" = "BRAN2020")
    on.exit(Sys.setenv("bluelink.BRANVERSION" = "BRAN2023"))
  }
  varname <- match.arg(varname)

  if (varname %in% c("ocean_mld")) level <- 1L  ##FIXME: warn/message on this


  x <- as.Date(x)[1]
  level <- level[1L]
  band <- as.integer(format(x, "%d"))

  if (length(level) < 1 || level < 1 || level > 51 || is.na(level)) stop("only 51 levels available")

  out <- .generate_raster(x, varname = varname, band = band,  level = level)
  terra::ext(out) <- terra::ext(round(as.vector(terra::ext(out))))
  out
}

