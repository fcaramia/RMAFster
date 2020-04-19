.onLoad <- function(libname, pkgname){

  py_avail = reticulate::py_available()
  if(py_avail==F){
    stop("Python not found, RMAFster uses python3, you can install a python environment with install_miniconda(), or install python in your system")
  }
}
