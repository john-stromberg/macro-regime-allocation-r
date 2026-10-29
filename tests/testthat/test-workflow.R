test_that("both configured economic models run end to end without network access", {
  root <- testthat::test_path("..", "..")
  cfg <- yaml::read_yaml(file.path(root, "config", "config.yml"))
  returns <- load_asset_returns(file.path(root, cfg$data$asset_returns_csv))
  baseline <- load_baseline_weights(file.path(root, cfg$data$baseline_weights_csv))
  macro <- monthly_macro_panel(macro_fixture())
  macro$data_vintage <- "synthetic_fixture"
  signals <- compute_macro_signals(macro, cfg$regime$lookback_months, cfg$regime$direction_months)
  for (definition in names(cfg$allocation)) {
	threshold <- if (definition == "growth_level_inflation_direction") {
	  cfg$regime$growth_level_threshold
	} else {
	  cfg$regime$growth_direction_threshold
	}
	regimes <- label_regime(signals, threshold, cfg$regime$inflation_threshold,
	  definition, cfg$regime$persistence_months)
	weights <- allocation_from_regime(regimes, cfg$allocation[[definition]])
	strategy <- compute_strategy_returns(returns, weights, baseline,
	  cfg$backtest$signal_lag_months, cfg$backtest$transaction_cost_bps)
	performance <- summarize_performance(strategy)
	by_regime <- summarize_by_regime(strategy)
	expect_equal(strategy$date, returns$date)
	expect_equal(performance$periods, nrow(returns))
	expect_equal(sum(by_regime$obs), nrow(returns))
	expect_true(all(is.finite(strategy$tilted_return)))
	expect_true(all(strategy$signal_date < strategy$date))
	expect_true(all(strategy$data_vintage == "synthetic_fixture"))
	expect_true(all(strategy$tilted_return <= strategy$tilted_gross_return + 1e-12))
	expect_equal(performance$tilted_annualized_turnover, mean(strategy$tilted_turnover) * 12)
	path <- tempfile(fileext = ".csv")
	withr::defer(unlink(path))
	expect_equal(write_output(performance, path), path)
	expect_equal(readr::read_csv(path, show_col_types = FALSE)$periods, nrow(returns))
  }
})
