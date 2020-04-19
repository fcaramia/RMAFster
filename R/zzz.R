.onLoad <- function(libname, pkgname){

  py_avail = reticulate::py_available()
  if(py_avail==F){
    warning("Python not found, when calling RmafsterCalc() for the first time, you'll be prompted to install a python environment with Conda, select (y) or install python in your system")
  }
}
