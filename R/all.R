all_dsn <- function( varname = c("ocean_temp", "atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force",
                                   "ocean_mld", "ocean_salt", "ocean_tx_trans_int_z",
                                   "ocean_ty_trans_int_z", "ocean_u", "ocean_v", "ocean_w")) {

  sdate <- as.Date("1993-01-01")
  dates <- seq(sdate, Sys.Date(), by = "1 day")
  v <- match.arg(varname)
  dsn <- unlist(lapply(dates, bluelink_dsn, varname = v))

  ## start from now and zap backwards
  ok <- logical(length(dsn))
  ok[] <- TRUE
  chk <- function(x) gdalraster::vsi_stat(x)
  for (i in seq(length(ok), 1)) {
    tst <- chk(dsn[i])
    if (tst) {
      break;
    } else {
      ok[i] <- FALSE
    }
  }

  for (i in seq(1, length(ok))) {
    tst <- chk(dsn[i])
    if (tst) {
      break;
    } else {
      ok[i] <- FALSE
    }

  }



  dsn[ok]

}
