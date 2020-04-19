.onLoad <- function(libname, pkgname){
  rmafster <<- import_from_path(module = 'RMAFster',path = 'inst/python/')
}
