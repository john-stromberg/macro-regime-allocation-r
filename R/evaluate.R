library(dplyr)

validate_strategy_returns <- function(df) {
  columns <- c("baseline_return", "tilted_return", "active_return")
  require_columns(df, c("date", "regime", columns), "Strategy returns")
  validate_monthly(df, "Strategy returns")
  if (!all(vapply(df[columns], is.numeric, logical(1))) ||
	  any(!is.finite(as.matrix(df[columns]))) ||
	  any(df$baseline_return <= -1 | df$tilted_return <= -1) || anyNA(df$regime)) {
	stop("Strategy returns must have finite returns greater than -1 and explicit regime labels", call. = FALSE)
  }
  if (any(abs(df$active_return - (df$tilted_return - df$baseline_return)) > 1e-10)) {
	stop("Active returns must equal tilted minus baseline net returns", call. = FALSE)
  }
}

maximum_drawdown <- function(returns) {
  wealth <- c(1, cumprod(1 + returns))
  min(wealth / cummax(wealth) - 1)
}

summarize_performance <- function(strategy_df) {
  validate_strategy_returns(strategy_df)
  strategy_df <- arrange(strategy_df, date)
  n <- nrow(strategy_df)
  baseline <- strategy_df$baseline_return
  tilted <- strategy_df$tilted_return
  active <- strategy_df$active_return
  baseline_wealth <- prod(1 + baseline)
  tilted_wealth <- prod(1 + tilted)
  tracking_error <- sd(active) * sqrt(12)
  average <- function(column) {
	if (column %in% names(strategy_df)) mean(strategy_df[[column]]) else NA_real_
  }
  tibble(
	start_date = min(strategy_df$date), end_date = max(strategy_df$date), periods = n,
	fallback_periods = sum(strategy_df$regime == "baseline_fallback"),
	baseline_cum = baseline_wealth - 1,
	tilted_cum = tilted_wealth - 1,
	active_cum = tilted_wealth - baseline_wealth,
	relative_cum = tilted_wealth / baseline_wealth - 1,
	baseline_annualized_return = baseline_wealth^(12 / n) - 1,
	tilted_annualized_return = tilted_wealth^(12 / n) - 1,
	baseline_annualized_vol = sd(baseline) * sqrt(12),
	tilted_annualized_vol = sd(tilted) * sqrt(12),
	active_mean = mean(active), active_vol = sd(active),
	tracking_error = tracking_error,
	information_ratio = if (is.finite(tracking_error) && tracking_error > 1e-12) mean(active) * 12 / tracking_error else NA_real_,
	baseline_max_drawdown = maximum_drawdown(baseline),
	tilted_max_drawdown = maximum_drawdown(tilted),
	baseline_annualized_turnover = average("baseline_turnover") * 12,
	tilted_annualized_turnover = average("tilted_turnover") * 12,
	baseline_average_cost = average("baseline_cost"),
	tilted_average_cost = average("tilted_cost")
  )
}

summarize_by_regime <- function(strategy_df) {
	validate_strategy_returns(strategy_df)
  strategy_df %>%
	group_by(regime) %>%
	summarise(
	  obs = n(),
	  share = n() / nrow(strategy_df),
	  avg_baseline = mean(baseline_return),
	  avg_tilted = mean(tilted_return),
	  avg_active = mean(active_return),
	  vol_active = sd(active_return),
	  .groups = "drop"
	)
}
