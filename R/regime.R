library(dplyr)

compute_macro_signals <- function(macro_df, lookback_months = 12, direction_months = 3) {
  validate_count(lookback_months, "lookback_months")
  validate_count(direction_months, "direction_months")
  require_columns(macro_df, c("date", "growth_proxy", "inflation_proxy"), "Macro panel")
  validate_monthly(macro_df, "Macro panel", consecutive = FALSE)
  levels <- macro_df[c("growth_proxy", "inflation_proxy")]
  if (!all(vapply(levels, is.numeric, logical(1))) ||
	  any(is.infinite(as.matrix(levels))) || any(as.matrix(levels) <= 0, na.rm = TRUE)) {
	stop("Growth and inflation proxies must be positive levels or missing", call. = FALSE)
  }
  macro_df$date <- month_end(macro_df$date)
  tibble(date = month_sequence(min(macro_df$date), max(macro_df$date))) %>%
	left_join(macro_df, by = "date") %>%
	arrange(date) %>%
	mutate(
	  growth_level = growth_proxy / dplyr::lag(growth_proxy, lookback_months) - 1,
	  inflation_level = inflation_proxy / dplyr::lag(inflation_proxy, lookback_months) - 1,
	  growth_direction = growth_level - dplyr::lag(growth_level, direction_months),
	  inflation_direction = inflation_level - dplyr::lag(inflation_level, direction_months)
	)
}

confirm_regimes <- function(regimes, persistence_months = 2) {
  validate_count(persistence_months, "persistence_months")
  out <- rep(NA_character_, length(regimes))
  candidate <- confirmed <- NA_character_
  count <- 0L
  for (i in seq_along(regimes)) {
	if (is.na(regimes[i])) {
	  candidate <- confirmed <- NA_character_
	  count <- 0L
	  next
	}
	count <- if (!is.na(candidate) && regimes[i] == candidate) count + 1L else 1L
	candidate <- regimes[i]
	if (count >= persistence_months) confirmed <- candidate
	out[i] <- confirmed
  }
  out
}

label_regime <- function(signal_df, growth_threshold = 0, inflation_threshold = 0,
						 definition = "growth_level_inflation_direction", persistence_months = 2) {
  definition <- match.arg(definition, c("growth_level_inflation_direction", "growth_direction_inflation_direction"))
  require_columns(signal_df, c("date", "growth_level", "growth_direction", "inflation_direction"), "Signals")
  validate_monthly(signal_df, "Signals")
  thresholds <- c(growth_threshold, inflation_threshold)
  if (!is.numeric(thresholds) || length(thresholds) != 2 || any(!is.finite(thresholds))) {
	stop("Regime thresholds must be finite numbers", call. = FALSE)
  }
  use_level <- definition == "growth_level_inflation_direction"
  out <- signal_df %>%
	arrange(date) %>%
	mutate(
	  regime_definition = definition,
	  growth_signal = if (use_level) growth_level else growth_direction,
	  inflation_signal = inflation_direction,
	  growth_state = if_else(growth_signal >= growth_threshold,
		if (use_level) "expanding" else "accelerating",
		if (use_level) "contracting" else "decelerating"),
	  inflation_state = if_else(inflation_signal >= inflation_threshold, "rising", "falling"),
	  raw_regime = if_else(is.finite(growth_signal) & is.finite(inflation_signal),
		paste0("growth_", growth_state, "_inflation_", inflation_state), NA_character_)
	)
  out$regime <- confirm_regimes(out$raw_regime, persistence_months)
  out
}
