library(targets)
tar_option_set(packages = c("dplyr", "tidyr", "readr", "purrr", "yaml"))

source("R/utils.R")
source("R/ingest.R")
source("R/fred_data.R")
source("R/regime.R")
source("R/allocation.R")
source("R/evaluate.R")

list(
  tar_target(config_file, "config/config.yml", format = "file"),
  tar_target(cfg, yaml::read_yaml(config_file)),
  tar_target(asset_returns_file, cfg$data$asset_returns_csv, format = "file"),
  tar_target(baseline_weights_file, cfg$data$baseline_weights_csv, format = "file"),
  tar_target(asset_returns, load_asset_returns(asset_returns_file)),
  tar_target(baseline_weights, load_baseline_weights(baseline_weights_file)),
  tar_target(macro_panel, load_macro_panel(cfg$data$fred_series,
	cfg$data$observation_start, cfg$data$observation_end), cue = tar_cue(mode = "always")),
  tar_target(macro_signals, compute_macro_signals(macro_panel,
	cfg$regime$lookback_months, cfg$regime$direction_months)),
  tar_target(regime_labeled, label_regime(macro_signals,
	growth_threshold = if (cfg$regime$definition == "growth_level_inflation_direction")
	  cfg$regime$growth_level_threshold else cfg$regime$growth_direction_threshold,
	inflation_threshold = cfg$regime$inflation_threshold,
	definition = cfg$regime$definition, persistence_months = cfg$regime$persistence_months)),
  tar_target(regime_weights, allocation_from_regime(regime_labeled, cfg$allocation[[cfg$regime$definition]])),
  tar_target(strategy_returns, compute_strategy_returns(asset_returns, regime_weights, baseline_weights,
	cfg$backtest$signal_lag_months, cfg$backtest$transaction_cost_bps)),
  tar_target(perf_summary, summarize_performance(strategy_returns)),
  tar_target(regime_summary, summarize_by_regime(strategy_returns)),
	tar_target(run_settings, tibble::tibble(
	data_vintage = unique(macro_panel$data_vintage),
	regime_definition = cfg$regime$definition,
	lookback_months = cfg$regime$lookback_months,
	direction_months = cfg$regime$direction_months,
	persistence_months = cfg$regime$persistence_months,
	growth_level_threshold = cfg$regime$growth_level_threshold,
	growth_direction_threshold = cfg$regime$growth_direction_threshold,
	inflation_threshold = cfg$regime$inflation_threshold,
	signal_lag_months = cfg$backtest$signal_lag_months,
	transaction_cost_bps = cfg$backtest$transaction_cost_bps)),
  tar_target(save_strategy, write_output(strategy_returns, "data_processed/strategy_returns.csv"), format = "file"),
  tar_target(save_perf, write_output(perf_summary, "data_processed/performance_summary.csv"), format = "file"),
	tar_target(save_regime, write_output(regime_summary, "data_processed/regime_summary.csv"), format = "file"),
  tar_target(save_signals, write_output(regime_labeled, "data_processed/macro_signals.csv"), format = "file"),
  tar_target(save_settings, write_output(run_settings, "data_processed/run_settings.csv"), format = "file")
)
