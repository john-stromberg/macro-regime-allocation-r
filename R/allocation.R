library(dplyr)
library(tidyr)

allocation_from_regime <- function(regime_df, allocation_cfg) {
	require_columns(regime_df, c("date", "regime"), "Regimes")
  validate_monthly(regime_df, "Regimes", consecutive = FALSE)
  if (!length(allocation_cfg) || is.null(names(allocation_cfg)) || anyDuplicated(names(allocation_cfg))) {
	stop("Allocation configuration must contain uniquely named regimes", call. = FALSE)
  }
  weights <- lapply(allocation_cfg, validate_weight_vector)
  if (any(!is.na(regime_df$regime) & !regime_df$regime %in% names(weights))) {
	stop("Allocation configuration is missing a regime", call. = FALSE)
  }
  out <- regime_df %>%
	select(date, regime, any_of(c("regime_definition", "data_vintage"))) %>%
	mutate(date = month_end(date)) %>%
	arrange(date)
  for (asset in c("equity", "bonds", "commodities")) {
	out[[paste0(asset, "_w")]] <- vapply(out$regime, function(label) {
	  if (is.na(label)) NA_real_ else weights[[label]][[asset]]
	}, numeric(1), USE.NAMES = FALSE)
  }
  out
}

compute_strategy_returns <- function(returns_df, tilt_df, baseline_weights,
									 signal_lag_months = 2, transaction_cost_bps = 10) {
  validate_asset_returns(returns_df)
  validate_monthly(tilt_df, "Tilt weights", consecutive = FALSE)
  assets <- c("equity", "bonds", "commodities")
  weight_cols <- paste0(assets, "_w")
  require_columns(tilt_df, c("regime", weight_cols), "Tilt weights")
  validate_count(signal_lag_months, "signal_lag_months")
  if (!is.numeric(transaction_cost_bps) || length(transaction_cost_bps) != 1 ||
	  !is.finite(transaction_cost_bps) || transaction_cost_bps < 0 || transaction_cost_bps >= 10000) {
	stop("transaction_cost_bps must be a number in [0, 10000)", call. = FALSE)
  }
  base <- baseline_vector(baseline_weights)
  for (i in which(!is.na(tilt_df$regime))) {
	validate_weight_vector(stats::setNames(unlist(tilt_df[i, weight_cols]), assets), "Tilt weights")
  }
  lagged <- tilt_df %>%
	mutate(signal_date = month_end(date), date = shift_month(date, signal_lag_months))
  out <- returns_df %>%
	select(date, all_of(assets)) %>%
	mutate(date = month_end(date)) %>%
	arrange(date) %>%
	left_join(lagged, by = "date") %>%
	mutate(used_baseline_fallback = is.na(regime),
		   regime = coalesce(regime, "baseline_fallback"))
  if (all(out$used_baseline_fallback)) {
	stop("No confirmed lagged regimes overlap the asset returns; check history and dates", call. = FALSE)
  }
  for (j in seq_along(assets)) {
	out[[weight_cols[j]]][out$used_baseline_fallback] <- base[j]
  }
  baseline_previous <- tilted_previous <- base
  for (column in c("baseline_gross_return", "tilted_gross_return", "baseline_turnover",
				   "tilted_turnover", "baseline_cost", "tilted_cost", "baseline_return", "tilted_return")) {
	out[[column]] <- numeric(nrow(out))
  }
  for (i in seq_len(nrow(out))) {
	asset_return <- as.numeric(out[i, assets])
	tilt <- as.numeric(out[i, weight_cols])
	baseline_gross <- sum(base * asset_return)
	tilted_gross <- sum(tilt * asset_return)
	baseline_turnover <- sum(abs(base - baseline_previous)) / 2
	tilted_turnover <- sum(abs(tilt - tilted_previous)) / 2
	baseline_cost <- baseline_turnover * transaction_cost_bps / 10000
	tilted_cost <- tilted_turnover * transaction_cost_bps / 10000
	out$baseline_gross_return[i] <- baseline_gross
	out$tilted_gross_return[i] <- tilted_gross
	out$baseline_turnover[i] <- baseline_turnover
	out$tilted_turnover[i] <- tilted_turnover
	out$baseline_cost[i] <- baseline_cost
	out$tilted_cost[i] <- tilted_cost
	out$baseline_return[i] <- (1 - baseline_cost) * (1 + baseline_gross) - 1
	out$tilted_return[i] <- (1 - tilted_cost) * (1 + tilted_gross) - 1
	baseline_previous <- base * (1 + asset_return) / (1 + baseline_gross)
	tilted_previous <- tilt * (1 + asset_return) / (1 + tilted_gross)
  }
  out %>%
	mutate(active_return = tilted_return - baseline_return) %>%
	select(-all_of(assets))
}
