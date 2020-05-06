RMAFster
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

RMAfster allows to calculate RNA mutated allele frequencies (RMAFs)
given a list of mutations and RNA-seq BAM files.

## Installation

You can install the development version from github using devtools:

``` r
# install.packages("devtools")
devtools::install_github("fcaramia/RMAFster")
```

## Basic example

``` r
library(RMAFster)
#> RMAFster uses a local python environment to execute RmafsterCalc,
#>   unless you specify a python environment using reticule::use_...
#>   you will be prompted to install miniconda the first time you use RmasterCalc.
#>   Select (Y) to proceed. Python dependencies will be handled automatically
samples = data.frame(
               sample_id='CT26',
               bam_path=system.file("extdata","CT26_chr8_115305465.bam",
               package = 'RMAFster', mustWork=TRUE),
               purity=1,
               stringsAsFactors = FALSE)
mutations = data.frame(
                 chr='chr8',
                 pos=115305465,
                 ref='G',
                 alt='A',
                 sample_id='CT26',
                 symbol ='Cntnap4')
RmafsterCalc(
     mutations,
     samples
)
#> Warning in RmafsterCalc(mutations, samples): var column not found in mutation
#> file, using SNP for all mutations
#> Warning in RmafsterCalc(mutations, samples): vaf column not found in mutation
#> file, using 0.5 for all mutations
#> Warning in RmafsterCalc(mutations, samples): dna_dp column not found in mutation
#> file, using 200 for all mutations
#>    chr       pos ref alt sample_id  symbol var vaf dna_dp ref_alleles
#> 1 chr8 115305465   G   A      CT26 Cntnap4 SNP 0.5    200           5
#>   alt_alleles other_alleles purity rna_dp rmaf
#> 1           5             0      1     10  0.5
```

Once RMAFs are calculated you can quickly explore them and compare
groups of genes/samples/etc..

``` r
rmafs = data.frame(
            rmaf = c(sample(800:1000,100,replace = TRUE)/1000,
                      sample(400:600,90,replace = TRUE)/1000,
                      sample(0:1000,80,replace = TRUE)/1000,
                      sample(0:300,60,replace = TRUE)/1000,
                      sample(1:1000,10,replace = TRUE)/1000
                     ),
            purity = c(rep(1,340)),
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
```

![](README-unnamed-chunk-2-1.png)<!-- -->

    #> # A tibble: 330 x 9
    #>    symbol n_muts  rmaf purity rna_dp dna_dp   vaf    z1    z2
    #>    <chr>   <int> <dbl>  <dbl>  <int>  <int> <dbl> <dbl> <dbl>
    #>  1 gene1     100 0.815      1     97    477 0.319  6.20  9.08
    #>  2 gene1     100 0.857      1    432    447 0.894 14.8  -1.66
    #>  3 gene1     100 0.904      1    285    135 0.467 13.6   9.84
    #>  4 gene1     100 0.806      1     33    112 0.231  3.52  6.04
    #>  5 gene1     100 0.804      1    470    425 0.431 13.2  11.5 
    #>  6 gene1     100 0.942      1    158    478 0.615 11.1   7.75
    #>  7 gene1     100 0.911      1    226    392 0.658 12.4   7.00
    #>  8 gene1     100 0.847      1    230    178 0.964 10.5  -3.87
    #>  9 gene1     100 0.993      1    500    491 0.734 22.0  11.9 
    #> 10 gene1     100 0.981      1    181    465 0.303 12.9  15.5 
    #> # … with 320 more rows
