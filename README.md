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
                rmaf = c(sample(800:900,100,replace = TRUE)/1000,
                          sample(400:600,90,replace = TRUE)/1000,
                          sample(0:900,80,replace = TRUE)/1000,
                          sample(0:300,60,replace = TRUE)/1000,
                          sample(1:900,10,replace = TRUE)/1000
                         ),
                rna_purity = c(rep(.9,340)),
                dna_purity = c(rep(.8,340)),
                rna_dp = c(sample(20:500,340,replace = TRUE)),
                dna_dp = c(sample(100:500,340,replace = TRUE)),
                vaf = c(sample(50:800,340,replace = TRUE)/1000),
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
    #>  1 gene1     100 0.847        0.9        0.8     28    241 0.097  4.22 10.1 
    #>  2 gene1     100 0.85         0.9        0.8    328    433 0.063 14.6  23.8 
    #>  3 gene1     100 0.822        0.9        0.8     77    238 0.407  6.56  6.32
    #>  4 gene1     100 0.833        0.9        0.8    415    151 0.302 15.7  13.9 
    #>  5 gene1     100 0.879        0.9        0.8    473    133 0.119 18.8  20.9 
    #>  6 gene1     100 0.848        0.9        0.8    461    359 0.421 17.2  13.8 
    #>  7 gene1     100 0.884        0.9        0.8    208    231 0.589 12.6   7.26
    #>  8 gene1     100 0.871        0.9        0.8    112    307 0.373  8.96  9.28
    #>  9 gene1     100 0.819        0.9        0.8    431    357 0.401 15.4  12.8 
    #> 10 gene1     100 0.895        0.9        0.8    448    129 0.279 18.9  18.1 
    #> # … with 320 more rows
