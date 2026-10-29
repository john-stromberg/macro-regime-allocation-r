library(readr)
library(dplyr)

load_asset_returns <- function(path) {
	out <- read_csv(path, show_col_types = FALSE) %>%
	mutate(date = month_end(as.Date(date))) %>%
	arrange(date)
  validate_asset_returns(out)
  out
}

load_baseline_weights <- function(path) {
	out <- read_csv(path, show_col_types = FALSE)
  baseline_vector(out)
  out
}

validate_asset_returns <- function(df) {
  assets <- c("equity", "bonds", "commodities")
  require_columns(df, c("date", assets), "Asset returns")
  validate_monthly(df, "Asset returns")
  if (!all(vapply(df[assets], is.numeric, logical(1))) ||
	  any(!is.finite(as.matrix(df[assets]))) || any(as.matrix(df[assets]) <= -1)) {
	stop("Asset returns must be finite decimal total returns greater than -1", call. = FALSE)
  }
}

baseline_vector <- function(df) {
  require_columns(df, c("asset", "weight"), "Baseline weights")
  validate_weight_vector(stats::setNames(df$weight, df$asset), "Baseline weights")
}
