.onLoad <- function(libname, pkgname) {
  BRANVERSION <-   getOption("bluelink.BRANVERSION")
  if (is.null(BRANVERSION) || nzchar(BRANVERSION)) {
    options("bluelink.BRANVERSION" = "BRAN2023")
  }
}
