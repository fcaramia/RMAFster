.onLoad <- function(libname, pkgname){
  reticulate::use_python('/usr/local/bin/python3',required)  ## try to use python on load so it can install anaconda
  reticulate::source_python(system.file('python/RMAFster.py',package = 'RMAFster',mustWork = T))
  rm(rmafster)
}
