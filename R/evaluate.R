library(dplyr)

summarize_performance <- function(strategy_df) {
  strategy_df %>%
	summarise(
	  periods = n(),
	  baseline_cum = prod(1 + baseline_return) - 1,
	  tilted_cum = prod(1 + tilted_return) - 1,
	  active_cum = prod(1 + active_return) - 1,
	  active_mean = mean(active_return, na.rm = TRUE),
	  active_vol = sd(active_return, na.rm = TRUE)
	)
}

summarize_by_regime <- function(strategy_df) {
  strategy_df %>%
	group_by(regime) %>%
	summarise(
	  obs = n(),
	  avg_active = mean(active_return, na.rm = TRUE),
	  vol_active = sd(active_return, na.rm = TRUE),
	  .groups = "drop"
	)
}
