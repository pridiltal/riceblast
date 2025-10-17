#' Visualize Fitted, Forecasted, and Extreme Error Patterns
#'
#' @description
#' Produces diagnostic visualizations from the results of
#' \code{\link{model_extremes}} and \code{\link{test_extremes}}.
#' The function generates two key plots:
#' \itemize{
#'   \item A time series plot of observed, fitted, and forecasted values.
#'   \item A diagnostic plot of residuals and forecast errors with the estimated
#'         lower extreme threshold marked.
#' }
#'
#' @param analysis_result A list object returned by
#'   \code{\link{test_extremes}}, containing the fitted model, forecast,
#'   threshold information, and error diagnostics.
#'
#' @details
#' The function visualizes both the model fit and the extremal analysis:
#' \itemize{
#'   \item The **main plot** shows the observed series (black), fitted values (blue),
#'         and forecasts (red), annotated with the thresholding method (EVT or boxplot).
#'   \item The **error plot** displays residuals and forecast errors over time.
#'         The horizontal dashed red line represents the lower extreme threshold,
#'         below which anomalies may occur.
#' }
#'
#' @return A list containing:
#' \describe{
#'   \item{main_plot}{A \code{ggplot2} object showing observed, fitted, and forecasted series.}
#'   \item{error_plot}{A \code{ggplot2} object showing residuals and forecast errors with threshold.}
#' }
#'
#' @examples
#' \dontrun{
#' library(tsibble)
#' library(fable)
#' library(ggplot2)
#'
#' # Run modeling and testing first
#' result <- model_extremes(
#'   full_data = mydata,
#'   typical_start = "2020-01-01",
#'   typical_end = "2020-03-31",
#'   response = temperature
#' )
#'
#' test_result <- test_extremes(result, h = 200)
#'
#' # Generate and view plots
#' plots <- plot_extreme_analysis(test_result)
#' plots$main_plot
#' plots$error_plot
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_point geom_hline labs theme_minimal
#' @importFrom ggplot2 autoplot autolayer
#' @importFrom glue glue
#' @importFrom rlang sym
#' @importFrom stats fitted
#' @export
plot_extreme_analysis <- function(analysis_result) {
  fit <- analysis_result$model
  fc <- analysis_result$forecast
  full_data <- analysis_result$full_data
  lower_limit <- analysis_result$lower_limit
  all_errors <- analysis_result$all_errors
  response <- analysis_result$response
  threshold_method <- analysis_result$threshold_method

  # Make sure the response symbol is properly recognized
  response_sym <- rlang::sym(response)

  # Main plot: Observed, Fitted, and Forecasted values
  p_main <- autoplot(full_data, !!response_sym) +
    autolayer(stats::fitted(fit), colour = "blue", alpha = 0.7) +
    autolayer(fc, colour = "red", alpha = 0.7) +
    labs(
      title = glue::glue(
        "Observed, Fitted, and Forecasted Values (Threshold: {toupper(threshold_method)})"
      ),
      y = response,
      x = "Time",
      colour = "Series"
    ) +
    theme_minimal()

  # Error plot: Residuals + Forecast errors
  p_error <- ggplot(all_errors, aes(x = time, y = error, colour = type)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, colour = "black") +
    geom_hline(yintercept = lower_limit, colour = "red", linetype = "dashed") +
    labs(
      title = glue::glue(
        "Residuals and Forecast Errors (Lower Limit by {toupper(threshold_method)})"
      ),
      y = "Error",
      x = "Time",
      colour = "Type"
    ) +
    theme_minimal()

  list(main_plot = p_main, error_plot = p_error)
}
