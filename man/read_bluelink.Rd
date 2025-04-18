% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bluelink.R
\name{read_bluelink}
\alias{read_bluelink}
\title{Title}
\usage{
read_bluelink(
  x,
  varname = c("ocean_salt", "ocean_temp", "ocean_u", "ocean_v", "ocean_w", "ocean_mld"),
  level = 1L,
  ...
)
}
\arguments{
\item{x}{date or datetime object or string}

\item{varname}{variable name one of "ocean_\if{html}{\out{<s>}}" salt, temp, u, v, w  (being salt=salinity, temp=temperature, u,v,w= velocity components in x,y,z direction)}

\item{level}{depth level (a value between 1 and 51, from the surface to the bottom) see Details}

\item{...}{unused currently}
}
\value{
SpatRaster
}
\description{
The 'level' argument is from 1 to 51, use 'terra::depth(x)' to disover the value.
Time is 'days since 1979-01-01 00:00:00'
See a representative ncdump output in examples, text saved in this package.
}
\details{
We can't quite support these collections:  "atm_flux_diag", "ice_force", "ocean_eta_t", "ocean_force", because they each have multiple variables.
Thinking about it ..., we probably need a function for each variable to make it work.
}
\examples{
read_bluelink(varname = "ocean_w")
read_bluelink("2023-01-05", "ocean_salt")
if(interactive()) {
 sfile <- "ncdump/atm_flux_diag_1993_01.nc.dump"
 sfile1 <- system.file(sfile, package = "bluelink", mustWork = TRUE)
 utils::browseURL(sfile1)
}
}
