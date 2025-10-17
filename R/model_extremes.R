#' Model typical behaviour and Estimate Lower Extreme Threshold
#'
#' @description
#' Fits an ARIMA model on a subset of the time series representing "typical" behavior
#' and estimates a lower extreme threshold based on either Extreme Value Theory (EVT)
#' using the Generalized Pareto Distribution (GPD) or a boxplot-based approach.
#'
#' @param full_data A tsibble object containing at least a time index column
#'  a response variable to be modeled.
#' @param time_col Name of the time index column.
#' @param typical_start Start date-time (character or POSIXct) defining the beginning
#'   of the typical observation window used for model fitting.
#' @param typical_end End date-time (character or POSIXct) defining the end
#'   of the typical observation window.
#' @param response The response variable to model, passed as an unquoted column name.
#' @param tail_prob Numeric value (default = 0.05). Tail probability used for defining
#'   the lower extreme threshold when `t_method = "evd"`.
#' @param t_method Character string indicating the threshold estimation method.
#'   Options are:
#'   \itemize{
#'     \item `"evd"` — estimates the threshold using the Generalized Pareto Distribution.
#'     \item `"boxplot"` — uses the boxplot rule (1.5 × IQR below Q1) to identify lower extremes.
#'   }
#'
#' @details
#' The function first subsets the input time series between `typical_start` and `typical_end`
#' to capture non-extreme, representative behavior. An ARIMA model is automatically fitted
#' using the `fable` framework, and residuals are extracted.
#'
#' Depending on the chosen `t_method`, the lower extreme threshold is estimated:
#' \itemize{
#'   \item For `"evd"` — the Generalized Pareto Distribution is fitted to the lower tail
#'         of residuals using \code{fpot()} from the \pkg{evd} package.
#'   \item For `"boxplot"` — the lower whisker (Q1 − 1.5 × IQR) is used as the threshold.
#' }
#'
#' @return A list containing:
#' \describe{
#'   \item{model}{The fitted ARIMA model object.}
#'   \item{lower_limit}{The estimated lower extreme threshold.}
#'   \item{threshold_method}{The threshold estimation method used (`"evd"` or `"boxplot"`).}
#'   \item{fitted_subset}{The subset of the time series used for model fitting.}
#'   \item{full_data}{The original full dataset provided.}
#'   \item{response}{The response variable name.}
#' }
#'
#' @examples
#' \dontrun{
#' # Create a sample daily time series dataset (use Date, not POSIXct)
#' data <- tsibble::tsibble(
#'   date = seq.Date(as.Date("2020-01-01"), as.Date("2020-12-31"), by = "day"),
#'   value = rnorm(366),
#'   index = date
#' )
#'
#' # Run the model_extremes function
#' result <- model_extremes(
#'   full_data = data,
#'   time_col = date,
#'   typical_start = "2020-01-01",
#'   typical_end = "2020-06-30",
#'   response = value,
#'   tail_prob = 0.05,
#'   t_method = "evd"
#' )
#' }
#'
#' @importFrom tsibble as_tsibble
#' @importFrom fabletools augment model
#' @importFrom evd fpot qgpd
#' @importFrom rlang ensym as_label
#' @importFrom fable ARIMA
#' @importFrom dplyr filter select mutate
#' @importFrom stats na.omit quantile IQR
#' @importFrom evd fpot qgpd
#' @export
#'
model_extremes <- function(full_data, time_col, typical_start, typical_end,
                           response, tail_prob = 0.05,
                           t_method = c("evd", "boxplot")) {

  t_method <- match.arg(t_method)
  response_sym <- rlang::ensym(response)
  time_sym <- rlang::ensym(time_col)

  # Ensure input is a tsibble with correct index
  if (!("tsibble" %in% class(full_data))) {
    full_data <- full_data |>
      tsibble::as_tsibble(index = !!time_sym)
  }

  # Subset for "typical" behavior
  data_subset <- full_data |>
    dplyr::filter( !!time_sym >= as.POSIXct(typical_start, tz = "UTC"),
                   !!time_sym <= as.POSIXct(typical_end, tz = "UTC") ) |>
    dplyr::select(!!time_sym, !!response_sym) |>
    tsibble::as_tsibble(index = !!time_sym)


  # Fit ARIMA model
  fit <- data_subset |> fabletools::model(fable::ARIMA(!!response_sym))

  # Extract residuals
  fitval <- fabletools::augment(fit) |> dplyr::mutate(residual = .resid)
  res <- stats::na.omit(fitval$residual)


  if (length(res) == 0 || all(is.na(res))) {
    warning("No residuals available for extreme value modeling. Returning NA.")
    return(NA)
  }

  # Threshold estimation

  if (t_method == "evd") {
    thr <- quantile(res, tail_prob)
    fit_gpd <- evd::fpot(-res, threshold = -thr)
    params <- fit_gpd$estimate
    lower_limit <- -evd::qgpd(
      tail_prob, loc = -thr,
      scale = params["scale"], shape = params["shape"]
    )
  } else if (t_method == "boxplot") {
    Q1 <- stats::quantile(res, 0.25)
    IQR_val <- stats::IQR(res)
    lower_limit <- Q1 - 1.5 * IQR_val
  }

  list(
    model = fit,
    lower_limit = lower_limit,
    threshold_method = t_method,
    fitted_subset = data_subset,
    full_data = full_data,
    response = rlang::as_label(response_sym)
  )
}
