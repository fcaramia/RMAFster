#' \lifecycle{experimental}
#'
#' @import patchwork
#' @import ggplot2
#' @import dplyr
#' @importFrom reshape2 melt
#' @importFrom ggpubr stat_cor
#'
#' @description explores RMAFs, the output of \code{RmafsterCalc()}, by calculating the z1 and z2 statistics and visualising using diverse plots.
#'
#' @name RmafsterExpl
#'
#' @param rmaf_df a data frame of rmafs.
#' The output from \code{RmafCalc()}
#' @param plot_by a character string.
#' Used to plot RMAFs by specific groups (maximum 12 values in group). Possible values are 'none' (default) or any column name from rmaf_df. E.g. 'symbol'.
#' @param min_num numeric.
#' The minimum number of mutations per group-value to be included in plots. E.g. if \code{plot_by} is \code{'chr'}, a chromosome is required to have \code{min_num} of mutations to be included in plot
#' @param print_plot logical.
#' If \code{TRUE} plot is shown
#' @return a data frame copy of \code{rmaf_df} with 2 additional columns: \code{"z1"} and \code{"z2"}, which correspond to the calculated statistics.
#' @examples
#' rmafs = data.frame(
#'             rmaf = c(sample(800:1000,100,replace = TRUE)/1000,
#'                       sample(400:600,90,replace = TRUE)/1000,
#'                       sample(0:1000,80,replace = TRUE)/1000,
#'                       sample(0:300,60,replace = TRUE)/1000,
#'                       sample(1:1000,10,replace = TRUE)/1000
#'                      ),
#'             purity = c(rep(1,340)),
#'             rna_dp = c(sample(20:500,340,replace = TRUE)),
#'             dna_dp = c(sample(100:500,340,replace = TRUE)),
#'             vaf = c(sample(50:1000,340,replace = TRUE)/1000),
#'             symbol = c(rep('gene1',100),
#'                        rep('gene2',90),
#'                        rep('gene3',80),
#'                        rep('gene4',60),
#'                        rep('gene5',10)),
#'              stringsAsFactors = FALSE
#'                )
#'
#' RmafsterExpl(
#'      rmafs,
#'      'symbol',
#'      20
#' )
#' @export
RmafsterExpl <- function(rmaf_df,plot_by='none',min_num = 20, print_plot = FALSE){

  if (dim(rmaf_df)[1] == 0 |dim(rmaf_df)[2] == 0) {
    stop('rmaf_df must contain data')
  }
  if(plot_by!='none'&!plot_by%in%colnames(rmaf_df)){
    stop('plot_by must be a column in rmaf_df')
  }
  if(min_num<1){
    stop('min_num must be larger than 0')
  }
  if(!all(c('rmaf','purity','rna_dp','dna_dp','vaf')%in%colnames(rmaf_df))){
    stop('missing columns in rmaf_df, required: "rmaf","purity","rna_dp","dna_dp","vaf"')
  }

  #Exclude genes with low number of mutations
  rmaf_df <- rmaf_df %>%
    group_by_at(plot_by) %>%
    summarise(n_muts=n()) %>%
    left_join(rmaf_df, by=plot_by) %>%
    filter(.data$n_muts>=min_num)

  #Calculate z1
  rmaf_df$z1 = ((rmaf_df$rmaf-0.5*rmaf_df$purity)) /
    sqrt(((0.5*rmaf_df$purity)*(1-0.5*rmaf_df$purity))/rmaf_df$rna_dp)

  #Calculate z2
  rmaf_df$p = (rmaf_df$rmaf*rmaf_df$rna_dp + rmaf_df$vaf*rmaf_df$dna_dp) /  (rmaf_df$rna_dp + rmaf_df$dna_dp)
  rmaf_df$var = rmaf_df$p*(1-rmaf_df$p)*((1/rmaf_df$rna_dp)+(1/rmaf_df$dna_dp))
  rmaf_df$z2 = ifelse(rmaf_df$var==0,0,((rmaf_df$rmaf - rmaf_df$vaf)) / sqrt(rmaf_df$var))
  rmaf_df$p = NULL
  rmaf_df$var = NULL

  #Melt the statistics
  rmaf_df_melt = melt(data = rmaf_df[,c('z1','z2',plot_by)], variable.name = 'z', value.name = 'z_val', id.vars=c(3))

  if(print_plot == TRUE){
  #Statistics plot
    p1 = ggplot(data = rmaf_df_melt, aes(sample = .data$z_val,color=.data$z)) +
      ggtitle(label = bquote(~'RMAFs'~ z[1]~ "and" ~z[2])) +
      ylab(label = bquote(z ~ 'values') ) +
      xlab(label = 'N(0,1)') +
      stat_qq() +
      facet_wrap(~get(plot_by)) +
      geom_abline(intercept = 0, slope = 1, color = "red", size = .5, alpha = 0.8) + theme_minimal() +
      scale_colour_discrete(name = bquote(z), labels = c(bquote(z[1]), bquote(z[2]))) +
      theme(plot.title = element_text(hjust = 0.5))

    p2 = ggplot(data = rmaf_df,aes(x = .data$rmaf,y= .data$vaf, color=get(plot_by))) +
      geom_point() +
      theme_minimal() +
      ggtitle(label = "RMAFs vs VAFs") +
      xlim(0,1) +
      ylim(0,1.5) +
      geom_abline(intercept = 0, slope = 1, color = "red", size = .5, alpha = 0.8) +
      xlab(label = 'RMAF')  +
      ylab('DNA VAF') +
      stat_cor(method = "pearson", label.x = .10,label.y.npc = 'top',size=2, aes(color = get(plot_by)))+
      theme(plot.title = element_text(hjust = 0.5)) +
      scale_colour_discrete(name = plot_by)

    p3 = ggplot(data = rmaf_df,aes(x = .data$rna_dp*.data$purity,y= .data$rmaf*.data$rna_dp, color=get(plot_by))) +
      geom_point() +
      theme_minimal() +
      ggtitle(label = "RMAFs") +
      geom_abline(intercept = 0, slope = 0.5, color = "red", size = .5, alpha = 0.8) +
      geom_abline(intercept = 0, slope = 1, color = "blue", size = .5, alpha = 0.8) +
      geom_abline(intercept = 0, slope = 0, color = "green", size = .5, alpha = 0.8) +
      xlab(label = 'Total mRNA reads * Purity')  + ylab('Mutated mRNA reads')+
      theme(plot.title = element_text(hjust = 0.5)) +
      scale_colour_discrete(name = plot_by)

    # Print Plot
    suppressWarnings(
      print(
        p1 / (p2 + p3)
      )
    )
  }


  rm(rmaf_df_melt)
  return(rmaf_df)
}
