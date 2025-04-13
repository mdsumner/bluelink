v <- c("ocean_temp", "atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force",
  "ocean_mld", "ocean_salt", "ocean_tx_trans_int_z",
  "ocean_ty_trans_int_z", "ocean_u", "ocean_v", "ocean_w")


l <- vector("list", length(v))
for (i in seq_along(l)) {
  dsn <- bluelink:::all_dsn(v[i])

  l[[i]] <- tibble::tibble(source = gsub("/vsicurl/", "", dsn), dataset = varname)
}

arrow::write_parquet(do.call(rbind, l), "inst/vzarr/bluelink.parquet")
