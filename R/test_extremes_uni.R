#' Test Model Extremes on Fitted and Forecasted Periods
#'
#' @description
#' Extends the analysis from \code{\link{model_extremes_uni}} by generating forecasts
#' and evaluating model residuals and forecast errors relative to the estimated
#' lower extreme threshold. This helps to assess whether future values fall within
#' the expected range or cross the lower extreme boundary. The function allows the
#' inclusion of new test data, which is combined with the training (typical) data
#' to create a complete dataset for residual and forecast error analysis.
#'
#' @param analysis_result A list object returned by \code{\link{model_extremes_uni}},
#'   containing the fitted model, lower limit, and related metadata.
#' @param test_data A tsibble or data frame containing the test/forecast period
#'   data. This will be combined with the typical_data from \code{model_extremes_uni}
#'   to form the full dataset used for error analysis.
#' @param h Integer. The forecast horizon, i.e., the number of future observations
#'   to predict. Default is 1000.
#'
#' @details
#' The function performs two main tasks:
#' \itemize{
#'   \item Generates forecasts (\code{h} steps ahead) using the fitted model.
#'   \item Combines fitted residuals (from the training window) and forecast errors
#'         (from the forecasted window) into a unified time series object for
#'         downstream analysis and visualization.
#' }
#'
#' Forecast errors are computed as the difference between the observed response
#' variable and the forecast mean. Both fitted and forecast errors are combined
#' with labels for easy comparison and plotting.
#'
#' @return A list containing:
#' \describe{
#'   \item{model}{The fitted model object from \code{model_extremes_uni}.}
#'   \item{forecast}{A \code{fable} forecast object containing mean forecasts and intervals.}
#'   \item{all_errors}{A \code{tsibble} containing both fitted residuals and forecast errors.}
#'   \item{lower_limit}{The estimated lower extreme threshold (from the model analysis).}
#'   \item{full_data}{The combined dataset consisting of \code{typical_data} and \code{test_data}.}
#'   \item{response}{The response variable name as a character string.}
#' }
#'
#' @examples
#'
#' # Create a sample daily time series dataset (use Date, not POSIXct)
#' data <- tsibble::tsibble(
#'   date = seq.Date(as.Date("2020-01-01"), as.Date("2020-12-31"), by = "day"),
#'   value = c(rnorm(300),rnorm(66, -3)),
#'   index = date
#' )
#'
#' result <- model_extremes_uni(
#'   full_data = data,
#'   time_col = date,
#'   typical_start = "2020-01-01",
#'   typical_end = "2020-08-30",
#'   response = value,
#'   thr_prob_fit = 0.1,
#'   t_method = "boxplot"
#' )
#'
#' test_data <- data |>
#'   dplyr::filter(date > as.Date("2020-06-30")) |>
#'   dplyr::select(date, value) |>
#'   tsibble::as_tsibble(index = date)
#'
#' test_result <- riceblast::test_extremes_uni(result,test_data = test_data,  h = 200)
#'
#' test_result
#'
#' @importFrom fabletools augment forecast
#' @importFrom tsibble as_tsibble
#' @importFrom tibble as_tibble
#' @importFrom dplyr select mutate left_join bind_rows
#' @importFrom rlang sym
#' @export
test_extremes_uni <- function(analysis_result, test_data, h = 1000)
{
  fit <- analysis_result$model
  lower_limit <- analysis_result$lower_limit
  typical_data <- analysis_result$typical_data
  response <- analysis_result$response
  time_col    <- analysis_result$time_col

  # Create sym objects
  time_sym     <- rlang::sym(time_col)
  response_sym <- rlang::sym(response)

  if (!("tsibble" %in% class(test_data))) {
    test_data <- test_data |> tsibble::as_tsibble(index = !!time_sym)
  }

  test_data <- test_data |>
    dplyr::filter(!!time_sym > max(typical_data[[time_col]]))

  full_data <- dplyr::bind_rows(typical_data, test_data) |>
    tsibble::as_tsibble(index = !!time_sym)

  # Forecast
  fc <- fit |> fabletools::forecast(h = h)

  # Fitted residuals
  fitval <- fabletools::augment(fit) |>
    dplyr::mutate(error = .resid, type = "Fitted Residual") |>
    dplyr::select({{time_sym}}, error, type)

  # Forecast errors
  fc_errors <- fc |>
    tibble::as_tibble() |>
    select( {{time_sym}}, .mean) |>
    dplyr::left_join(test_data |> tibble::as_tibble(), by = rlang::as_string(time_sym)) |>
    dplyr::mutate(error = !!response_sym - .mean, type = "Forecast Error") |>
    dplyr::select({{time_sym}}, error, type)

  # Combine both
  all_errors <- dplyr::bind_rows(fitval, fc_errors) |>
    tsibble::as_tsibble(index = !!time_sym)

  # Return combined results
  list(
    model       = fit,
    forecast    = fc,
    all_errors  = all_errors,
    lower_limit = lower_limit,
    full_data   = full_data,
    response = rlang::as_label(response_sym),
    time_col = rlang::as_string(time_sym)
  )
}
