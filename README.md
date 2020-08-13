RMAFster
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

RMAfster allows to calculate RNA mutated allele frequencies (RMAFs)
given a list of mutations and RNA-seq BAM files.

Installation
------------

You can install the development version from github using devtools:

    # install.packages("devtools")
    devtools::install_github("fcaramia/RMAFster")

Basic example
-------------

    library(RMAFster)
    #> RMAFster uses a local python environment to execute RmafsterCalc,
    #>   unless you specify a python environment using reticule::use_...
    #>   you will be prompted to install miniconda the first time you use RmasterCalc.
    #>   Select (Y) to proceed. Python dependencies will be handled automatically
    samples = data.frame(
                   sample_id='CT26',
                   bam_path=system.file("extdata","CT26_chr8_115305465.bam",
                   package = 'RMAFster', mustWork=TRUE),
                   rna_purity=1,
                   dna_purity=1,
                   stringsAsFactors = FALSE)
    mutations = data.frame(
                     chr='chr8',
                     pos=115305465,
                     ref='G',
                     alt='A',
                     sample_id='CT26',
                     symbol ='Cntnap4')
    rmafs = RmafsterCalc(
         mutations,
         samples
    )
    #> Warning in RmafsterCalc(mutations, samples): var column not found in mutation
    #> table, using SNP for all mutations
    #> Warning in RmafsterCalc(mutations, samples): vaf column not found in mutation
    #> table, using 0.5 for all mutations
    #> Warning in RmafsterCalc(mutations, samples): dna_dp column not found in mutation
    #> table, using 200 for all mutations

Once RMAFs are calculated you can quickly explore them and compare
groups of genes/samples/etc..

    rmafs = data.frame(
                rmaf = c(sample(800:1000,100,replace = TRUE)/1000,
                          sample(400:600,90,replace = TRUE)/1000,
                          sample(0:1000,80,replace = TRUE)/1000,
                          sample(0:300,60,replace = TRUE)/1000,
                          sample(1:1000,10,replace = TRUE)/1000
                         ),
                rna_purity = c(rep(1,340)),
                dna_purity = c(rep(1,340)),
                rna_dp = c(sample(20:500,340,replace = TRUE)),
                dna_dp = c(sample(100:500,340,replace = TRUE)),
                vaf = c(sample(50:1000,340,replace = TRUE)/1000),
                symbol = c(rep('gene1',100),
                           rep('gene2',90),
                           rep('gene3',80),
                           rep('gene4',60),
                           rep('gene5',10)),
                 stringsAsFactors = FALSE
                   )

    RmafsterExpl(
         rmafs,
         'symbol',
         20,
         print_plot = TRUE
    )

![](man/figures/README-plot-1.png)<!-- -->

    #> # A tibble: 330 x 10
    #>    symbol n_muts  rmaf rna_purity dna_purity rna_dp dna_dp   vaf    z1    z2
    #>    <chr>   <int> <dbl>      <dbl>      <dbl>  <int>  <int> <dbl> <dbl> <dbl>
    #>  1 gene1     100 0.895          1          1    415    141 0.332 16.1  13.4 
    #>  2 gene1     100 0.94           1          1    212    211 0.094 12.8  17.4 
    #>  3 gene1     100 0.805          1          1    156    440 0.291  7.62 11.2 
    #>  4 gene1     100 0.845          1          1    351    328 0.123 12.9  18.8 
    #>  5 gene1     100 0.883          1          1    488    278 0.996 16.9  -5.68
    #>  6 gene1     100 0.883          1          1     82    149 0.656  6.94  3.75
    #>  7 gene1     100 0.966          1          1     80    196 0.155  8.34 12.5 
    #>  8 gene1     100 0.844          1          1    110    155 0.649  7.22  3.52
    #>  9 gene1     100 0.965          1          1    144    263 0.734 11.2   5.75
    #> 10 gene1     100 0.809          1          1    252    181 0.893  9.81 -2.38
    #> # … with 320 more rows
