
<!-- README.md is generated from README.Rmd. Please edit that file -->

# riceblast

<!-- badges: start -->

<!-- badges: end -->

The goal of `riceblast` is to provides data and tools for forecasting
rice blast disease outbreaks using weather-based parameters. It combines
climate variables (such as temperature, humidity, and rainfall) with
knowledge of disease development to build predictive models and early
warning systems. The package helps researchers, agronomists, and
policymakers understand and anticipate disease risks, supporting
sustainable management strategies to reduce crop losses and improve food
security.

## Installation

You can install the development version of riceblast from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("pridiltal/riceblast")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(riceblast)
head(field1)
#>                  time      d2m      t2m     stl1      u10         v10
#> 1          2020-11-01 297.3382 298.0059 299.2812 1.668137  0.40396118
#> 2 2020-11-01 01:00:00 297.5522 298.2703 299.3481 1.724533  0.48725891
#> 3 2020-11-01 02:00:00 297.2091 300.0403 300.6789 1.980438  0.33197021
#> 4 2020-11-01 03:00:00 296.5240 301.8020 303.1999 2.288300  0.20007324
#> 5 2020-11-01 04:00:00 295.8354 303.0580 305.2274 2.332153  0.08836365
#> 6 2020-11-01 05:00:00 294.6398 304.3468 307.4920 2.431274 -0.45683289
#>             tp    type       RH
#> 1 4.490495e-04 typical 96.08358
#> 2 0.000000e+00 typical 95.80187
#> 3 1.017004e-06 typical 84.51785
#> 4 2.481043e-06 typical 73.17257
#> 5 2.909452e-06 typical 65.27463
#> 6 2.913177e-06 typical 56.37305
```
