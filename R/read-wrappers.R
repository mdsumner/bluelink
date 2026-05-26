.bran_gdal_vars <- c(
  GDAL_DISABLE_READDIR_ON_OPEN  = "EMPTY_DIR",
  GDAL_HTTP_MERGE_CONSECUTIVE_RANGES = "YES",
  GDAL_HTTP_MULTIPLEX           = "YES",
  GDAL_HTTP_VERSION             = "2",
  CPL_VSIL_CURL_CACHE_SIZE      = "67108864"
)

.set_gdal_vsicurl <- function() {
  old <- Sys.getenv(names(.bran_gdal_vars), unset = NA_character_, names = TRUE)
  do.call(Sys.setenv, as.list(.bran_gdal_vars))
  invisible(old)
}

.unset_gdal_vsicurl <- function(old) {
  set   <- !is.na(old)
  unset <- is.na(old)
  if (any(set))   do.call(Sys.setenv,   as.list(old[set]))
  if (any(unset)) Sys.unsetenv(names(old)[unset])
  invisible(NULL)
}

.epoch <- ISOdatetime(1979, 1, 1, 0, 0, 0, tz = "UTC")

.do_terra <- function(dsn, band, level) {
  old <- .set_gdal_vsicurl()
  on.exit(.unset_gdal_vsicurl(old), add = TRUE)
  out <- terra::rast(dsn, vsi = TRUE)
  nl  <- if (terra::nlyr(out) < 50) 1L else 51L
  out <- out[[level + (band - 1L) * nl]]
  # depth from layer name
  sv <- stringr::str_extract(names(out), "(?<=st_ocean=)[^_]+")
  terra::depth(out) <- if (!is.na(sv)) as.numeric(sv) else 2.5
  # time from layer name
  tv <- stringr::str_extract(names(out), "(?<=Time=)[^_]+")
  if (!is.na(tv)) terra::time(out) <- .epoch + as.numeric(tv) * 86400
  out
}

.do_raster <- function(dsn, band, level) {
  requireNamespace("ncdf4", quietly = TRUE)
  ht  <- suppressMessages(tidync::hyper_transforms(tidync::tidync(dsn)))
  out <- terra::rast(raster::raster(dsn, band = band, level = level) * 1)
  if (!is.null(ht$Time$Time))
    terra::time(out) <- .epoch + as.numeric(ht$Time$Time[band]) * 86400
  if (!is.null(ht$st_ocean$st_ocean))
    terra::depth(out) <- ht$st_ocean$st_ocean[level]
  else
    terra::depth(out) <- 2.5
  terra::crs(out) <- "EPSG:4326"
  out
}

#' Read bluelink data to raster
#'
#' The 'level' argument is from 1 to 51, use 'terra::depth(x)' to disover the value.
#' Time is 'days since 1979-01-01 00:00:00'
#' See a representative ncdump output in examples, text saved in this package.
#'
#' We can't quite support these collections:  "atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force", because they each have multiple variables.
#' Thinking about it ..., we probably need a function for each variable to make it work.

#' @param date date or datetime object or string
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
read_bluelink <- function(date,
                          varname = c("ocean_salt", "ocean_temp",
                                      "ocean_u", "ocean_v", "ocean_w", "ocean_mld"),
                          level = 1L, ...) {
  orig <- Sys.getenv("")
  if (missing(date)) date <- as.Date("2010-01-01")
  varname <- match.arg(varname)
  date    <- as.Date(date)[1]
  level   <- level[1L]
  if (varname == "ocean_mld") level <- 1L
  if (is.na(level) || level < 1 || level > 51) stop("level must be 1-51")

  band <- as.integer(format(date, "%d"))

  if (.Platform$OS.type == "windows" || Sys.info()[["sysname"]] == "Darwin") {
    dsn <- bluelink_uri(date, varname, access = "dodsC")
    out <- .do_raster(dsn, band, level)
  } else {
    dsn <- bluelink_uri(date, varname, access = "vsicurl")
    out <- .do_terra(dsn, band, level)
  }
  terra::ext(out) <- terra::ext(round(as.vector(terra::ext(out))))
  out
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
