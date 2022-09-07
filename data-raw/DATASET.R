ucat <- "https://dapds00.nci.org.au/thredds/catalog/gb6/BRAN/BRAN2020/daily/catalog.html"
icat <- readLines(ucat)
library(stringr)
library(dplyr)
library(vapour)
library(whatarelief)
urs <- str_extract(icat, "dataset=.*nc'")
urs <- urs[!is.na(urs)]

urs <- gsub("'$", "", gsub("dataset=", "", urs) )

u <- "https://dapds00.nci.org.au/thredds/dodsC/gb6/BRAN/BRAN2020/daily/ocean_u_2010_01.nc"
RNetCDF::open.nc(u)
dsn <- "/vsicurl/https://dapds00.nci.org.au/thredds/fileServer/gb6/BRAN/BRAN2020/daily/ocean_u_2010_01.nc"

allbran <- tibble::tibble(fileurl = file.path("https://dapds00.nci.org.au/thredds/fileServer", urs),
                          dsn = file.path("/vsicurl", fileurl),
                          ncurl = file.path("https://dapds00.nci.org.au/thredds/dodsC", urs))


#dput(unique(unlist(lapply(strsplit(basename(x$fileurl), "_"), function(.x) paste0(head(.x, -2), collapse = "_")))))
branvariables <-
c("atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force",
"ocean_mld", "ocean_salt", "ocean_temp", "ocean_tx_trans_int_z",
"ocean_ty_trans_int_z", "ocean_u", "ocean_v", "ocean_w")



ocean_temp <- allbran |> filter(str_detect(fileurl, "ocean_temp"))
## expand to every time step
ustring <- ncmeta::nc_atts(ocean_temp$ncurl[1]) |>
  dplyr::filter(variable == "Time", name == "units") |>
  tidyr::unnest(cols = "value") |>
  dplyr::pull(value)
nc_to_date <- function(x) {
  ISOdatetime(x[,1], x[,2], x[,3], x[,4], x[,5], x[,6], tz = "UTC")
}

l <- vector("list", nrow(ocean_temp))
for (i in seq_len(nrow(ocean_temp))) {
  nc <- RNetCDF::open.nc(ocean_temp$ncurl[i])
  zlevel0 <- RNetCDF::var.get.nc(nc, "st_ocean")
  date0 <- nc_to_date(RNetCDF::utcal.nc(ustring, RNetCDF::var.get.nc(nc, "Time")))
  RNetCDF::close.nc(nc)
  #bandstart <- (seq_along(date)-1) * 51 + 1

  l[[i]] <- tibble::tibble(date = rep(date0, each = length(zlevel0)), zlevel = rep(seq_along(zlevel0), length(date0)),
                           z = rep(zlevel0, length(date0))) |> dplyr::mutate( band = dplyr::row_number())
}

ocean_temp$bands <- l
saveRDS(ocean_temp, "inst/extdata/ocean_temp.rds")
#
# i <- nrow(x)
# info0 <- vapour_raster_info(x$dsn[i], sds = 2)
#
# par(mfrow = n2mfrow(31), mar = rep(0, 4))
# band <- 1
# l <- vector("list", 31)
# for (i in 1:31) {
# ## we have to skip 51 depth levels to get to the next surface time step
# vrt <- vapour_vrt(x$dsn[i], sds = 2, projection = "OGC:CRS84", bands = band <- band + 1 * 51)
#
# ex0 <- c(-75, -50, 63, 75) + c(360, 360, 0, 0)
# qu <- vaster::vcrop(ex0, info0$extent, info0$dimension)
# ex <- qu$extent
# dm <- qu$dimension
# sst <- elevation(source = vrt, extent = ex, dimension = dm)
# library(ximage)
# #l[[i]] <- range(sst, na.rm = T)
# rn <- c(-1.85, 8.5)
# ximage(sst, extent = ex, zlim = rn, asp = 1/cos(mean(ex[3:4] * pi/180)), col = hcl.colors(54))
# maps::map("world2", add = TRUE)
# }
#
#
# ## start count
# d1 <- vaster::col_from_x(info0$extent, info0$dimension, ex[1:2])
# d2 <- vaster::row_from_y(info0$extent, info0$dimension, ex[3:4])
#
# nc <- RNetCDF::open.nc(x$ncurl[i])
# arr <- RNetCDF::var.get.nc(nc, "temp",
#                            start = c(2851, 1, 15, 1),
#                            count = c(diff(d1), 121, 1, 30))
#
#
