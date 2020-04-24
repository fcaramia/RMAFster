#' \lifecycle{experimental}
#'
#' @description calculates RMAFs for a set of mutations in specific BAM files.
#'
#' @importFrom data.table fread
#' @importFrom data.table fwrite
#' @importFrom reticulate source_python
#' @importFrom dplyr left_join
#'
#' @name RmafsterCalc
#'
#' @param mutations a data frame of mutations.
#' Required columns:
#' chr: chromosome,
#' pos: genomic position,
#' ref: reference or wildtype allele,
#' alt: mutated allele.
#' Optional Columns:
#' symbol: gene symbol,
#' sample_id: the mutations are specific for samples, if \code{NULL} all mutations are searched in all samples,
#' var: mutations type, defaults to \code{'SNP'},
#' vaf: variant allele frequency for mutation (defaults to \code{0.5}),
#' dna_dp: depth of dna sequencing for mutation (defaults to \code{200})
#' @param samples a data frame of samples
#' Required columns:
#' sample_id: an id for each sample,
#' bam_path: full path for .bam file (.bai file must be present in the same directory).
#' Optional columns:
#' purity: tumour purity for sample (defaults to \code{1})
#' @return a data frame copy of \code{mutations} with 6 additional columns: \code{"ref_alleles"}, \code{"alt_alleles"}, \code{"other_alleles"}, \code{"purity"}, \code{"rna_dp"} and \code{"rmaf"}.
#' @examples
#' samples = data.frame(
#'                sample_id='CT26',
#'                bam_path=system.file("extdata","CT26_chr8_115305465.bam",
#'                package = 'RMAFster', mustWork=TRUE),
#'                purity=1,
#'                stringsAsFactors = FALSE)
#' mutations = data.frame(
#'                  chr='chr8',
#'                  pos=115305465,
#'                  ref='G',
#'                  alt='A',
#'                  sample_id='CT26',
#'                  symbol ='Cntnap4')
#' RmafsterCalc(
#'      mutations,
#'      samples
#' )
#' @export
RmafsterCalc <- function(mutations=NULL, samples=NULL){

  ##The holder for the python function
  rmafster = NULL
  ##Get the RMAFSter function from python module
  source_python(system.file('python/RMAFster.py',package = 'RMAFster',mustWork = T))

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
  fwrite(mutations,"mutation_file.csv",sep = ',')
  cmd_m_file = paste('-m',"mutation_file.csv",sep = '')
  cmd_o_file = paste('-o',"output_file.csv",sep = '')

  if(use_all==T){
    cmd_samples = c(paste("-a",paste(samples$bam_path,samples$sample_id,sep = ':'),sep = ''))
  } else {
    cmd_samples = c(paste("-i",paste(samples$bam_path,samples$sample_id,sep = ':'),sep = ''))
  }
  ##Call RMAFster function in python
  rmafster(c(cmd_m_file,cmd_o_file,cmd_samples))

  if (file.exists('output_file.csv')) {
    #Delete file if it exists
    ret_df = fread('output_file.csv',stringsAsFactors = F)
    file.remove('output_file.csv')
  } else {
    stop("RMAFster did not finish, exiting")
  }

  if (file.exists('mutation_file.csv')) {
    #Delete file if it exists
    file.remove('mutation_file.csv')
  }

  #Merge mutations with purity
  if( !'purity'%in%colnames(samples) ){
    warning('purity column not found in samples file, using 1 for all samples')
    mutations$purity = 1
  }else{
    ret_df <- left_join(ret_df,samples[,c('sample_id','purity')],by = c('sample_id'))
  }
  ret_df$rna_dp = ret_df$ref_alleles + ret_df$alt_alleles + ret_df$other_alleles
  ret_df$rmaf = ifelse(ret_df$rna_dp==0,NA,ret_df$alt_alleles/ret_df$rna_dp)
  return(ret_df)
}
