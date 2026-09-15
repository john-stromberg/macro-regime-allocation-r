library(dplyr)
library(tidyr)

allocation_from_regime <- function(regime_df, allocation_cfg) {
  regime_df %>%
	filter(!is.na(regime)) %>%
	mutate(
	  equity_w = purrr::map_dbl(regime, ~ allocation_cfg[[.x]][1]),
	  bonds_w = purrr::map_dbl(regime, ~ allocation_cfg[[.x]][2]),
	  commodities_w = purrr::map_dbl(regime, ~ allocation_cfg[[.x]][3])
	) %>%
	select(date, regime, equity_w, bonds_w, commodities_w)
}

compute_strategy_returns <- function(returns_df, tilt_df, baseline_weights) {
  base <- baseline_weights %>% tibble::deframe()

  returns_df %>%
	inner_join(tilt_df, by = "date") %>%
	mutate(
	  baseline_return = equity * base[["equity"]] + bonds * base[["bonds"]] + commodities * base[["commodities"]],
	  tilted_return = equity * equity_w + bonds * bonds_w + commodities * commodities_w,
	  active_return = tilted_return - baseline_return
	) %>%
	select(date, regime, baseline_return, tilted_return, active_return)
}
