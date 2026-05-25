# ---- URI core ---------------------------------------------------------------

.bran_version <- function(date) {
  if (as.Date(date) < as.Date("2010-01-01")) "BRAN2020" else "BRAN2023"
}

.bran_filename <- function(varname, date, time.resolution = c("daily", "month", "annual")) {
  time.resolution <- match.arg(time.resolution)
  date <- as.Date(date)[1]
  switch(time.resolution,
         daily  = sprintf("daily/%s_%s.nc",     varname, format(date, "%Y_%m")),
         month  = sprintf("month/%s_mth_%s.nc", varname, format(date, "%Y_%m")),
         annual = sprintf("annual/%s_ann_%s.nc", varname, format(date, "%Y"))
  )
}

.bran_path <- function(varname, date,
                       time.resolution = "daily",
                       version = .bran_version(date)) {
  file.path("gb6/BRAN", version, .bran_filename(varname, date, time.resolution))
}

.bran_base <- "https://thredds.nci.org.au/thredds"

#' Generate BRAN URIs for GDAL or OPeNDAP access
#'
#' @param date date string or Date; defaults to 2024-06-30
#' @param varname one of the BRAN variable names
#' @param time.resolution "daily", "month", or "annual"
#' @param version BRAN version string, auto-detected from date if NULL
#' @param access one of "vsicurl" (default), "dodsC", or "bare"
#' @return character URI
#' @export
#' @examples
#' bluelink_uri("2023-03-15", "ocean_temp")
#' bluelink_uri("2023-03-15", "ocean_w", access = "dodsC")
#' bluelink_uri("1993-06-01", "ocean_salt")  # -> BRAN2020
bluelink_uri <- function(date,
                         varname = c("atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force",
                                     "ocean_mld", "ocean_salt", "ocean_temp",
                                     "ocean_tx_trans_int_z", "ocean_ty_trans_int_z",
                                     "ocean_u", "ocean_v", "ocean_w"),
                         time.resolution = c("daily", "month", "annual"),
                         version = NULL,
                         access = c("vsicurl", "dodsC", "bare")) {
  if (missing(date)) date <- "2024-06-30"  # TODO: discover latest
  varname        <- match.arg(varname)
  time.resolution <- match.arg(time.resolution)
  access         <- match.arg(access)
  date           <- as.Date(date)[1]
  if (is.na(date)) stop("bad date input")

  ver  <- version %||% .bran_version(date)
  path <- .bran_path(varname, date, time.resolution, version = ver)

  switch(access,
         vsicurl = sprintf("/vsicurl/%s/fileServer/%s", .bran_base, path),
         dodsC   = sprintf("%s/dodsC/%s",               .bran_base, path),
         bare    = sprintf("%s/fileServer/%s",           .bran_base, path)
  )
}

# Keep old name as alias for now
#' @rdname bluelink_uri
#' @export
bluelink_dsn <- bluelink_uri
