.onLoad <- function(libname, pkgname){
  warning("RMAFster uses a local python environment to execute RmafsterCalc,
  unless you specify a python environment using reticule::use_...
  you will be prompted to install miniconda the first time you use RmasterCalc.
  Select (Y) to proceed. Python dependencies will be handled automatically")

}
