.onLoad <- function(libname, pkgname){
  rmafster <<- reticulate::import_from_path(module = 'RMAFster',path = 'inst/python/')
}
