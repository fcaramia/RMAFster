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
#' @param rmaf_tbl a data frame of rmafs.
#' The output from \code{RmafCalc()}
#' @param plot_by_str a character string.
#' Used to plot RMAFs by specific groups (maximum 12 values in group). Possible values are 'none' (default) or any column name from rmaf_df. E.g. 'symbol'.
#' @param min_num_int numeric.
#' The minimum number of mutations per group-value to be included in plots. E.g. if \code{plot_by_str} is \code{'chr'}, a chromosome is required to have \code{min_num_int} of mutations to be included in plot
#' @param print_plot_lgc logical.
#' If \code{TRUE} plot is shown
#' @param return_plot_list logical.
#' If \code{TRUE} a list of objects is returned
#' @param remove_outliers logical
#' If \code{TRUE} remove z1 ad z2 outliers
#' @return a data frame copy of \code{rmaf_tbl} with 2 additional columns: \code{"z1"} and \code{"z2"}, which correspond to the calculated statistics. If \code{return_plot_list} == \code{TRUE} a list of objects is returned
#' @examples
#' rmafs = data.frame(
#'             rmaf = c(sample(800:900,100,replace = TRUE)/1000,
#'                       sample(400:600,90,replace = TRUE)/1000,
#'                       sample(0:900,80,replace = TRUE)/1000,
#'                       sample(0:300,60,replace = TRUE)/1000,
#'                       sample(1:900,10,replace = TRUE)/1000
#'                      ),
#'             rna_purity = c(rep(.9,340)),
#'             dna_purity = c(rep(.8,340)),
#'             rna_dp = c(sample(20:500,340,replace = TRUE)),
#'             dna_dp = c(sample(100:500,340,replace = TRUE)),
#'             vaf = c(sample(50:800,340,replace = TRUE)/1000),
#'             symbol = c(rep('gene1',100),
#'                        rep('gene2',90),
#'                        rep('gene3',80),
#'                        rep('gene4',60),
#'                        rep('gene5',10)),
#'              stringsAsFactors = FALSE
#'                )
#'
#' RmafsterExpl(
#'      rmaf_tbl = rmafs,
#'      plot_by_str = 'symbol',
#'      min_num_int = 20
#' )
#' @export
RmafsterExpl <- function(rmaf_tbl,plot_by_str='none',min_num_int = 20, print_plot_lgc = FALSE, return_plot_list = FALSE, remove_outliers = FALSE){

  if (dim(rmaf_tbl)[1] == 0 |dim(rmaf_tbl)[2] == 0) {
    stop('rmaf_tbl must contain data')
  }
  if(plot_by_str!='none'&!plot_by_str%in%colnames(rmaf_tbl)){
    stop('plot_by_str must be a column in rmaf_tbl')
  }
  if(min_num_int<1){
    stop('min_num must be larger than 0')
  }
  if(!all(c('rmaf','rna_purity','dna_purity','rna_dp','dna_dp','vaf')%in%colnames(rmaf_tbl))){
    stop('missing columns in rmaf_tbl, required: "rmaf","rna_purity","dna_purity","rna_dp","dna_dp","vaf"')
  }

  #Exclude genes with low number of mutations
  if (plot_by_str == 'none'){
    rmaf_tbl$none = 1
  }
  rmaf_tbl <- rmaf_tbl %>%
    group_by_at(plot_by_str) %>%
    summarise(n_muts=n()) %>%
    left_join(rmaf_tbl, by=plot_by_str) %>%
    filter(.data$n_muts>=min_num_int)

  #Calculate z1
  rmaf_tbl$z1 = ((rmaf_tbl$rmaf-0.5*rmaf_tbl$rna_purity)) /
    sqrt(((0.5*rmaf_tbl$rna_purity)*(1-0.5*rmaf_tbl$rna_purity))/rmaf_tbl$rna_dp)

  #Calculate z2
  rmaf_tbl$p = ( ((rmaf_tbl$rmaf*rmaf_tbl$rna_dp)/rmaf_tbl$rna_purity) +
                   (rmaf_tbl$vaf*rmaf_tbl$dna_dp)/rmaf_tbl$dna_purity) /
    (rmaf_tbl$rna_dp + rmaf_tbl$dna_dp)
  rmaf_tbl$var = (rmaf_tbl$p*(1-rmaf_tbl$p))*((1/rmaf_tbl$rna_dp)+(1/rmaf_tbl$dna_dp))
  rmaf_tbl$z2 = ifelse(rmaf_tbl$var==0,0,((rmaf_tbl$rmaf/rmaf_tbl$rna_purity) - (rmaf_tbl$vaf/rmaf_tbl$dna_purity)) / sqrt(rmaf_tbl$var))
  rmaf_tbl$p = NULL
  rmaf_tbl$var = NULL

  #Remove outliers
  if(remove_outliers == TRUE){
    remove_outliers <- function(x) {
      qnt <- quantile(x, probs=c(.25, .75), na.rm = TRUE)
      H <- 1.5 * IQR(x, na.rm = TRUE)
      y <- x
      y[x < (qnt[1] - H)] <- NA
      y[x > (qnt[2] + H)] <- NA
      y
    }
    rmaf_tbl$z1 = remove_outliers(rmaf_tbl$z1)
    rmaf_tbl$z1 = remove_outliers(rmaf_tbl$z2)
  }

  #Melt the statistics
  rmaf_melt_tbl = melt(data = rmaf_tbl[,c('z1','z2',plot_by_str)], variable.name = 'z', value.name = 'z_val', id.vars=c(3))

  if(print_plot_lgc == TRUE | return_plot_list == TRUE){
  #Statistics plot
    p1 = ggplot(data = rmaf_melt_tbl, aes(sample = .data$z_val,color=.data$z)) +
      ggtitle(label = bquote(~'RMAFs'~ z[1]~ "and" ~z[2])) +
      ylab(label = bquote(z ~ 'values') ) +
      xlab(label = 'N(0,1)') +
      stat_qq() +
      facet_wrap(~get(plot_by_str)) +
      geom_abline(intercept = 0, slope = 1, color = "red", size = .5, alpha = 0.8) + theme_minimal() +
      scale_colour_discrete(name = bquote(z), labels = c(bquote(z[1]), bquote(z[2]))) +
      theme(plot.title = element_text(hjust = 0.5))

    p2 = ggplot(data = rmaf_tbl,aes(x = .data$rmaf/.data$rna_purity,y= .data$vaf/.data$dna_purity, color=get(plot_by_str))) +
      geom_point() +
      theme_minimal() +
      ggtitle(label = "RMAFs vs VAFs") +
      xlim(0,1) +
      ylim(0,1.5) +
      geom_abline(intercept = 0, slope = 1, color = "red", size = .5, alpha = 0.8) +
      xlab(label = 'RMAF/RNA Purity')  +
      ylab('DNA VAF/DNA Purity') +
      stat_cor(method = "pearson", label.x = .10,label.y.npc = 'top',size=2, aes(color = get(plot_by_str)))+
      theme(plot.title = element_text(hjust = 0.5)) +
      scale_colour_discrete(name = plot_by_str)

    p3 = ggplot(data = rmaf_tbl,aes(x = .data$rna_dp*.data$rna_purity,y= .data$rmaf*.data$rna_dp, color=get(plot_by_str))) +
      geom_point() +
      theme_minimal() +
      ggtitle(label = "RMAFs") +
      geom_abline(intercept = 0, slope = 0.5, color = "red", size = .5, alpha = 0.8) +
      geom_abline(intercept = 0, slope = 1, color = "blue", size = .5, alpha = 0.8) +
      geom_abline(intercept = 0, slope = 0, color = "green", size = .5, alpha = 0.8) +
      xlab(label = 'Total mRNA reads * RNA_Purity')  + ylab('Mutated mRNA reads')+
      theme(plot.title = element_text(hjust = 0.5)) +
      scale_colour_discrete(name = plot_by_str)

    # Print Plot
    if (print_plot_lgc == TRUE){
      suppressWarnings(
        print(
          p1 / (p2 + p3)
        )
      )
    }
  }


  rm(rmaf_melt_tbl)
  if (return_plot_list==TRUE){
    return(list(rmaf_tbl,p1,p2,p3))
  }
  return(rmaf_tbl)
}
