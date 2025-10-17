#' Test Model Extremes on Fitted and Forecasted Periods
#'
#' @description
#' Extends the analysis from \code{\link{model_extremes}} by generating forecasts
#' and evaluating model residuals and forecast errors relative to the estimated
#' lower extreme threshold. This helps to assess whether future values fall within
#' the expected range or cross the lower extreme boundary.
#'
#' @param analysis_result A list object returned by \code{\link{model_extremes}},
#'   containing the fitted model, lower limit, and related metadata.
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
#'   \item{model}{The fitted model object from \code{analysis_result}.}
#'   \item{forecast}{A \code{fable} forecast object containing mean forecasts and intervals.}
#'   \item{all_errors}{A \code{tsibble} containing both fitted residuals and forecast errors.}
#'   \item{lower_limit}{The estimated lower extreme threshold (inherited from the model analysis).}
#'   \item{full_data}{The complete input dataset used for modeling and testing.}
#'   \item{response}{The response variable name as a character string.}
#' }
#'
#' @examples
#' \dontrun{
#' library(tsibble)
#' library(fable)
#'
#' # Assume model_extremes() has been run
#' result <- model_extremes(
#'   full_data = mydata,
#'   typical_start = "2020-01-01",
#'   typical_end = "2020-03-31",
#'   response = temperature
#' )
#'
#' test_result <- test_extremes(result, h = 200)
#'
#' test_result$all_errors
#' }
#'
#' @importFrom fabletools augment forecast
#' @importFrom tsibble as_tsibble
#' @importFrom tibble as_tibble
#' @importFrom dplyr select mutate left_join bind_rows
#' @importFrom rlang sym
#' @export
test_extremes <- function(analysis_result, h = 1000) {
  fit <- analysis_result$model
  lower_limit <- analysis_result$lower_limit
  full_data <- analysis_result$full_data
  response <- analysis_result$response

  response_sym <- rlang::sym(response)

  # Forecast
  fc <- fit |> fabletools::forecast(h = h)

  # Fitted residuals
  fitval <- augment(fit) |> dplyr::mutate(error = .resid, type = "Fitted Residual") |>
    dplyr::select(time, error, type)

  # Forecast errors
  fc_errors <- fc |>
    tibble::as_tibble() |>
    dplyr::select(time, .mean) |>
    dplyr::left_join(full_data |> as_tibble(), by = "time") |>
    dplyr::mutate(error = !!response_sym - .mean, type = "Forecast Error") |>
    dplyr::select(time, error, type)

  # Combine both
  all_errors <- dplyr::bind_rows(fitval, fc_errors) |>
    tsibble::as_tsibble(index = time)

  # Return combined results
  list(
    model = fit,
    forecast = fc,
    all_errors = all_errors,
    lower_limit = lower_limit,
    full_data = full_data,
    response = response
  )
}
