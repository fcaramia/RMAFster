.onLoad <- function(libname, pkgname){

  if(!reticulate::py_available()){
    warning("RMAFster uses a local python environment to execute RmafsterCalc,
          unless you specify a python environment using reticule::use...
          you will be prompted to install miniconda. Select (Y) to proceed.
          Python dependencies will be handled automatically")
  }

}
