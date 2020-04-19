.onLoad <- function(libname, pkgname){
  reticulate::use_python('/usr/local/bin/python3',required = T)  ## try to use python on load so it can install anaconda
}
