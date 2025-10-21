
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

You can install the development version of riceblast from
[GitHub](https://github.com/pridiltal/riceblast) with:

``` r
# install.packages("pak")
pak::pak("pridiltal/riceblast")
```

## Example

This is an example dataset available in the riceblast package. For more
examples, please refer to the package vignettes.

``` r
library(riceblast)
head(field1)
#> # A tibble: 6 × 9
#>   time                  d2m   t2m  stl1   u10     v10         tp type       RH
#>   <dttm>              <dbl> <dbl> <dbl> <dbl>   <dbl>      <dbl> <chr>   <dbl>
#> 1 2020-11-01 01:00:00  298.  298.  299.  1.72  0.487  0          typical  95.8
#> 2 2020-11-01 02:00:00  297.  300.  301.  1.98  0.332  0.00000102 typical  84.5
#> 3 2020-11-01 03:00:00  297.  302.  303.  2.29  0.200  0.00000248 typical  73.2
#> 4 2020-11-01 04:00:00  296.  303.  305.  2.33  0.0884 0.00000291 typical  65.3
#> 5 2020-11-01 05:00:00  295.  304.  307.  2.43 -0.457  0.00000291 typical  56.4
#> 6 2020-11-01 06:00:00  294.  305.  309.  2.47 -1.22   0.00000291 typical  51.4
```
