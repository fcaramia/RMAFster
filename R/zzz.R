.onLoad <- function(libname, pkgname){
  reticulate::source_python(system.file('python/RMAFster.py',package = 'RMAFster',mustWork = T))
}
