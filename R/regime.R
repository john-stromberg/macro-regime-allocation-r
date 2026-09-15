library(dplyr)
library(slider)

compute_macro_signals <- function(macro_df, lookback_months = 12) {
  macro_df %>%
	arrange(date) %>%
	mutate(
	  growth_signal = growth_proxy / dplyr::lag(growth_proxy, lookback_months) - 1,
	  inflation_signal = inflation_proxy / dplyr::lag(inflation_proxy, lookback_months) - 1
	)
}

label_regime <- function(signal_df, growth_threshold = 0, inflation_threshold = 0) {
  signal_df %>%
	mutate(
	  regime = case_when(
		growth_signal >= growth_threshold & inflation_signal < inflation_threshold ~ "growth_up_inflation_down",
		growth_signal >= growth_threshold & inflation_signal >= inflation_threshold ~ "growth_up_inflation_up",
		growth_signal < growth_threshold & inflation_signal < inflation_threshold ~ "growth_down_inflation_down",
		TRUE ~ "growth_down_inflation_up"
	  )
	)
}
