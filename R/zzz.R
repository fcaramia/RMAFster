.onLoad <- function(libname, pkgname){

  avail = reticulate::py_available()
  if(avail == FALSE){
    warning("RMAFster uses a local python environment to execute RmafsterCalc,
          unless you specify a python environment using reticule::use...
          you will be prompted to install miniconda. Select (Y) to proceed.
          Python dependencies will be handled automatically")
  }

}
