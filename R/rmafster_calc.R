#' @export
RmafsterCalc <- function(mutations=NULL, samples=NULL){

  use_all = F
  if(is.null(mutations)){
    stop("mutations are required")
  }
  if(is.null(samples)){
    stop("sample file is required")
  }

  if( !'ref'%in%colnames(mutations) ){
    stop("ref column missing in mutation file")
  }
  if( !'pos'%in%colnames(mutations) ){
    stop("pos column missing in mutation file")
  }
  if( !'alt'%in%colnames(mutations) ){
    stop("alt column missing in mutation file")
  }
  if( !'chr'%in%colnames(mutations) ){
    stop("chr column missing in mutation file")
  }
  if( !'sample_id'%in%colnames(mutations) ){
    warning("sample_id column missing in mutation file, searching mutations in all samples")
    use_all = T
    mutations$sample_id = 'all'
  }
  if( !'var'%in%colnames(mutations) ){
    warning('var column not found in mutation file, using SNP for all mutations')
    mutations$var = 'SNP'
  }
  if( !'vaf'%in%colnames(mutations) ){
    warning('vaf column not found in mutation file, using 0.5 for all mutations')
    mutations$vaf = 0.5
  }
  if( !'dna_dp'%in%colnames(mutations) ){
    warning('dna_dp column not found in mutation file, using 200 for all mutations')
    mutations$dna_dp = 200
  }

  if( !'sample_id'%in%colnames(samples) ){
    stop("sample_id column missing in sample file")
  }
  if( !'bam_path'%in%colnames(samples) ){
    stop("bam_path column missing in sample file")
  }
  if( !'purity'%in%colnames(samples) ){
    warning('purity column not found in sample file, using 1 for all samples')
    mutations$purity = 1
  }

  data.table::fwrite(mutations,"mutation_file.csv",sep = ',')
  cmd_m_file = paste('-m',"mutation_file.csv",sep = '')
  cmd_o_file = paste('-o',"output_file.csv",sep = '')

  if(use_all==T){
    cmd_samples = c(paste("-a",paste(samples$bam_path,samples$sample_id,sep = ':'),sep = ''))
  } else {
    cmd_samples = c(paste("-i",paste(samples$bam_path,samples$sample_id,sep = ':'),sep = ''))
  }

  ##Get the RMAFSter function from python script
  reticulate::source_python(system.file('python/RMAFster.py',package = 'RMAFster',mustWork = T))
  ##Call RMAFster function in python
  rmafster(c(cmd_m_file,cmd_o_file,cmd_samples))

  if (file.exists('output_file.csv')) {
    #Delete file if it exists
    ret_df = data.table::fread('output_file.csv')
    file.remove('output_file.csv')
  } else {
    stop("RMAFster did not finish, exiting")
  }

  if (file.exists('mutations_file.csv')) {
    #Delete file if it exists
    file.remove('mutations_file.csv')
  }

  rm(rmafster)
  return(ret_df)

}
