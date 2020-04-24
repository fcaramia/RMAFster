#' \lifecycle{experimental}
#'
#' @export
RmafsterExpl <- function(rmaf_df,plot_by='symbol',min_num = 20){

  if (dim(rmaf_df)[1] == 0 |dim(rmaf_df)[2] == 0) {
    stop('rmaf_df must contain data')
  }
  if(!plot_by%in%colnames(rmaf_df)){
    stop('plot_by must be a column in rmaf_df')
  }

  #Calculate z1
  rmaf_df$z1 = ((rmaf_df$rmaf-0.5*rmaf_df$purity)) /
    sqrt(((0.5*rmaf_df$purity)*(1-0.5*rmaf_df$purity))/rmaf_df$rna_dp)

  #Calculate z2
  rmaf_df$p = (rmaf_df$rmaf*rmaf_df$rna_dp + rmaf_df$vaf*rmaf_df$dna_dp) /  (rmaf_df$rna_dp + rmaf_df$dna_dp)
  rmaf_df$var = rmaf_df$p*(1-rmaf_df$p)*((1/rmaf_df$rna_dp)+(1/rmaf_df$dna_dp))
  rmaf_df$z2 = ifelse(rmaf_df$var==0,0,((rmaf_df$rmaf - rmaf_df$vaf)) / sqrt(rmaf_df$var))


}
