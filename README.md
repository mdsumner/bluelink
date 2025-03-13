
<!-- README.md is generated from README.Rmd. Please edit that file -->

# bluelink

<!-- badges: start -->

[![R-CMD-check](https://github.com/mdsumner/bluelink/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mdsumner/bluelink/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of bluelink is to provide access to the Bluelink Reanalysis
(BRAN2023) via NetCDF sources.

## Bluelink is

BRAN2023, a 4 dimensional nearly-global ocean product organized by
monthly files at 0.1 degree resolution with 51 depth levels
(‘3600x1500x51x<days>’). The goal of BRAN is to provide a realistic
quantitative description of the three-dimensional time-varying ocean
circulation of all physical variables (temperature, salinity, sea-level
and three components of velocity) for the last few decades.
<https://research.csiro.au/bluelink/global/reanalysis/>

## Installation

You can install the development version of bluelink like so:

``` r
remotes::install_github("mdsumner/bluelink")
```

## Example

This is a basic example which shows you how to read the earliest
available for this variable.

``` r
library(bluelink)
read_bluelink(varname = "ocean_w")
#> class       : SpatRaster 
#> dimensions  : 1500, 3600, 1  (nrow, ncol, nlyr)
#> resolution  : 0.1, 0.1  (x, y)
#> extent      : 0, 360, -75, 75  (xmin, xmax, ymin, ymax)
#> coord. ref. : +proj=longlat +datum=WGS84 +no_defs 
#> source      : ocean_w_2010_01.nc:w 
#> varname     : w (dia-surface velocity T-points) 
#> name        : w_Time=11323.5_sw_ocean=5 
#> unit        :                     m/sec 
#> time        : 2010-01-01 12:00:00 UTC
```

Other variables sometimes have diferent ranges in times.

``` r
read_bluelink(varname = "ocean_temp")
#> class       : SpatRaster 
#> dimensions  : 1500, 3600, 1  (nrow, ncol, nlyr)
#> resolution  : 0.1, 0.1  (x, y)
#> extent      : 0, 360, -75, 75  (xmin, xmax, ymin, ymax)
#> coord. ref. : +proj=longlat +datum=WGS84 +no_defs 
#> source      : ocean_temp_2010_01.nc:temp 
#> varname     : temp (Potential temperature) 
#> name        : temp_Time=11323.5_st_ocean=2.5 
#> unit        :                      degrees C 
#> time        : 2010-01-01 12:00:00 UTC
```

We can give a particular date.

``` r
read_bluelink("2023-12-31", varname = "ocean_temp")
#> class       : SpatRaster 
#> dimensions  : 1500, 3600, 1  (nrow, ncol, nlyr)
#> resolution  : 0.1, 0.1  (x, y)
#> extent      : 0, 360, -75, 75  (xmin, xmax, ymin, ymax)
#> coord. ref. : +proj=longlat +datum=WGS84 +no_defs 
#> source      : ocean_temp_2023_12.nc:temp 
#> varname     : temp (Potential temperature) 
#> name        : temp_Time=16435.5_st_ocean=2.5 
#> unit        :                      degrees C 
#> time        : 2023-12-31 12:00:00 UTC
```

Generally, take the year you are in and you should be able to get days
from last year.

## Get just the url for use in GDAL

``` r
bluelink_dsn()
#> [1] "/vsicurl/https://thredds.nci.org.au/thredds/fileServer/gb6/BRAN/BRAN2023/daily/atm_flux_diag_2024_06.nc"

bluelink_dsn("2003-02-01", varname = "ocean_salt")
#> [1] "/vsicurl/https://thredds.nci.org.au/thredds/fileServer/gb6/BRAN/BRAN2020/daily/ocean_salt_2003_02.nc"
```

Substitute “/fileServer” for “/dodsC/” for use in netcdf or tidync, and
turn off “vsicurl”.

``` r
u <- bluelink_dsn("2003-02-01", varname = "ocean_salt", vsicurl = FALSE)
dods <- gsub("fileServer", "dodsC", u)
RNetCDF::print.nc(RNetCDF::open.nc(dods))

netcdf classic {
dimensions:
    Time = UNLIMITED ; // (28 currently)
    nv = 2 ;
    st_edges_ocean = 52 ;
    st_ocean = 51 ;
    xt_ocean = 3600 ;
    yt_ocean = 1500 ;
variables:
    NC_DOUBLE xt_ocean(xt_ocean) ;
        NC_CHAR xt_ocean:long_name = "tcell longitude" ;
        NC_CHAR xt_ocean:units = "degrees_E" ;
        NC_CHAR xt_ocean:cartesian_axis = "X" ;
        NC_INT xt_ocean:domain_decomposition = 1, 3600, 1, 1800 ;
        NC_INT xt_ocean:_ChunkSizes = 300 ;
    NC_DOUBLE yt_ocean(yt_ocean) ;
        NC_CHAR yt_ocean:long_name = "tcell latitude" ;
        NC_CHAR yt_ocean:units = "degrees_N" ;
        NC_CHAR yt_ocean:cartesian_axis = "Y" ;
        NC_INT yt_ocean:domain_decomposition = 1, 1500, 1, 150 ;
        NC_INT yt_ocean:_ChunkSizes = 300 ;
    NC_DOUBLE st_ocean(st_ocean) ;
        NC_CHAR st_ocean:long_name = "tcell
<snip>      
        
tidync::tidync(dods)

Data Source (1): ocean_salt_2003_02.nc ...

Grids (8) <dimension family> : <associated variables> 

[1]   D4,D5,D3,D0 : salt    **ACTIVE GRID** ( 7711200000  values per variable)
[2]   D1,D0       : Time_bounds
[3]   D0          : Time, average_T1, average_T2, average_DT
[4]   D1          : nv
[5]   D2          : st_edges_ocean
[6]   D3          : st_ocean
[7]   D4          : xt_ocean
[8]   D5          : yt_ocean

Dimensions 6 (4 active): 
  
  dim   name     length       min    max start count      dmin   dmax unlim coord_dim 
  <chr> <chr>     <dbl>     <dbl>  <dbl> <int> <int>     <dbl>  <dbl> <lgl> <lgl>     
1 D0    Time         28 8798.     8824.      1    28 8798.     8824.  TRUE  TRUE      
2 D3    st_ocean     51    2.5    4509.      1    51    2.5    4509.  FALSE TRUE      
3 D4    xt_ocean   3600    0.0500  360.      1  3600    0.0500  360.  FALSE TRUE      
4 D5    yt_ocean   1500  -74.9      74.9     1  1500  -74.9      74.9 FALSE TRUE      
  
Inactive dimensions:
  
  dim   name           length   min   max unlim coord_dim 
  <chr> <chr>           <dbl> <dbl> <dbl> <lgl> <lgl>     
1 D1    nv                  2     1     2 FALSE TRUE      
2 D2    st_edges_ocean     52     0  5000 FALSE TRUE 

```

## Try a time series

Every day on the first of September

``` r
dts <- seq(as.Date("2010-01-01"), as.Date("2023-10-10"), by = "1 year")

options(parallelly.fork.enable = TRUE, future.rng.onMisuse = "ignore")
library(furrr); plan(multicore)
#> Loading required package: future

sst <- future_map_dbl(dts, \(.x) terra::extract(read_bluelink(.x, varname = "ocean_temp"), cbind(150, -42))[[1]])
plan(sequential)
plot(dts, sst)
```

<img src="man/figures/README-time-1.png" width="100%" />

## Code of Conduct

Please note that the bluelink project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
