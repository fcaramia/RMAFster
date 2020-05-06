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

![](man/figures/README-plot-1.png)<!-- -->

    #> # A tibble: 330 x 9
    #>    symbol n_muts  rmaf purity rna_dp dna_dp   vaf    z1    z2
    #>    <chr>   <int> <dbl>  <dbl>  <int>  <int> <dbl> <dbl> <dbl>
    #>  1 gene1     100 0.928      1    295    329 0.751 14.7   5.94
    #>  2 gene1     100 0.814      1     27    397 0.315  3.26  5.27
    #>  3 gene1     100 0.899      1    263    397 0.807 12.9   3.19
    #>  4 gene1     100 0.819      1    377    135 0.075 12.4  15.3 
    #>  5 gene1     100 0.906      1    279    361 0.224 13.6  17.1 
    #>  6 gene1     100 0.962      1    282    466 0.144 15.5  21.8 
    #>  7 gene1     100 0.944      1    360    467 0.227 16.8  20.5 
    #>  8 gene1     100 0.891      1    212    304 0.747 11.4   4.07
    #>  9 gene1     100 0.858      1    121    215 0.34   7.88  9.13
    #> 10 gene1     100 0.801      1    209    451 0.425  8.70  9.02
    #> # … with 320 more rows
