.onLoad <- function(libname, pkgname){
  reticulate::use_python('/usr/local/bin/python3',required = T)  ## Check Python3 installation
}
