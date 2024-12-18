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
#' @param mutations_tbl a data frame of mutations.
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
#' dna_dp: depth of dna sequencing at mutation site (defaults to \code{200})
#' @param samples_tbl a data frame of samples
#' Required columns:
#' sample_id: an id for each sample,
#' bam_path: full path for .bam file (.bai file must be present in the same directory).
#' Optional columns:
#' rna_purity: tumour purity for rna sample (defaults to \code{1})
#' dna_purity: tumour purity for dna sample (defaults to \code{1})
#' @return a data frame copy of \code{mutations} with 7 additional columns: \code{"ref_alleles"}, \code{"alt_alleles"}, \code{"other_alleles"}, \code{"rna_purity"}, \code{"dna_purity"}, \code{"rna_dp"} and \code{"rmaf"}.
#' @examples
#' samples_tbl = data.frame(
#'                sample_id='CT26',
#'                bam_path=system.file("extdata","CT26_chr8_115305465.bam",
#'                package = 'RMAFster', mustWork=TRUE),
#'                rna_purity=1,
#'                dna_purity=1,
#'                stringsAsFactors = FALSE)
#' mutations_tbl = data.frame(
#'                  chr='chr8',
#'                  pos=115305465,
#'                  ref='G',
#'                  alt='A',
#'                  sample_id='CT26',
#'                  symbol ='Cntnap4')
#' rmafs = RmafsterCalc(
#'      mutations_tbl,
#'      samples_tbl
#' )
#' @export
RmafsterCalc <- function(mutations_tbl=NULL, samples_tbl=NULL){

  ##The holder for the python function
  rmafster = NULL
  ##Get the RMAFSter function from python module
  source_python(system.file('python/RMAFster.py',package = 'RMAFster',mustWork = T))

  use_all_mutations_lgc = F
  if(is.null(mutations_tbl)){
    stop("mutations are required")
  }
  if(is.null(samples_tbl)){
    stop("sample file is required")
  }

  if( !'ref'%in%colnames(mutations_tbl) ){
    stop("ref column missing in mutation table")
  }
  if( !'pos'%in%colnames(mutations_tbl) ){
    stop("pos column missing in mutation table")
  }
  if( !'alt'%in%colnames(mutations_tbl) ){
    stop("alt column missing in mutation table")
  }
  if( !'chr'%in%colnames(mutations_tbl) ){
    stop("chr column missing in mutation table")
  }
  if( !'sample_id'%in%colnames(mutations_tbl) ){
    warning("sample_id column missing in mutation table, searching mutations in all samples")
    use_all_mutations_lgc = T
    mutations_tbl$sample_id = 'all'
  }
  if( !'var'%in%colnames(mutations_tbl) ){
    warning('var column not found in mutation table, using SNP for all mutations')
    mutations_tbl$var = 'SNP'
  }
  if( !'vaf'%in%colnames(mutations_tbl) ){
    warning('vaf column not found in mutation table, using 0.5 for all mutations')
    mutations_tbl$vaf = 0.5
  }
  if( !'dna_dp'%in%colnames(mutations_tbl) ){
    warning('dna_dp column not found in mutation table, using 200 for all mutations')
    mutations_tbl$dna_dp = 200
  }

  if( !'sample_id'%in%colnames(samples_tbl) ){
    stop("sample_id column missing in sample table")
  }
  if( !'bam_path'%in%colnames(samples_tbl) ){
    stop("bam_path column missing in sample table")
  }
  fwrite(mutations_tbl,"mutation_file.csv",sep = ',')
  cmd_m_file_str = paste('-m',"mutation_file.csv",sep = '')
  cmd_o_file_str = paste('-o',"output_file.csv",sep = '')

  if(use_all_mutations_lgc==T){
    cmd_samples_str = c(paste("-a",paste(samples_tbl$bam_path,samples_tbl$sample_id,sep = ':'),sep = ''))
  } else {
    cmd_samples_str = c(paste("-i",paste(samples_tbl$bam_path,samples_tbl$sample_id,sep = ':'),sep = ''))
  }
  ##Call RMAFster function in python
  rmafster(c(cmd_m_file_str,cmd_o_file_str,cmd_samples_str))

  if (file.exists('output_file.csv')) {
    #Delete file if it exists
    ret_tbl = fread('output_file.csv',stringsAsFactors = F)
    file.remove('output_file.csv')
  } else {
    stop("RMAFster did not finish, exiting")
  }

  if (file.exists('mutation_file.csv')) {
    #Delete file if it exists
    file.remove('mutation_file.csv')
  }

  #Merge mutations with purity
  if( !'rna_purity'%in%colnames(samples_tbl) ){
    warning('rna_purity column not found in samples file, using 1 for all samples')
    mutations_tbl$rna_purity = 1

  }else{
    ret_tbl <- left_join(ret_tbl,samples_tbl[,c('sample_id','rna_purity')],by = c('sample_id'))
  }
  #Merge mutations with purity
  if( !'dna_purity'%in%colnames(samples_tbl) ){
    warning('dna_purity column not found in samples file, using 1 for all samples')
    mutations_tbl$dna_purity = 1

  }else{
    ret_tbl <- left_join(ret_tbl,samples_tbl[,c('sample_id','dna_purity')],by = c('sample_id'))
  }
  ret_tbl$rna_dp = ret_tbl$ref_alleles + ret_tbl$alt_alleles + ret_tbl$other_alleles
  ret_tbl$rmaf = ifelse(ret_tbl$rna_dp==0,NA,ret_tbl$alt_alleles/ret_tbl$rna_dp)
  return(ret_tbl)
}
