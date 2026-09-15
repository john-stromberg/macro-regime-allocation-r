library(targets)
tar_option_set(packages = c("tidyverse", "lubridate", "fredr", "slider", "yaml"))

source("R/ingest.R")
source("R/fred_data.R")
source("R/regime.R")
source("R/allocation.R")
source("R/evaluate.R")
source("R/utils.R")

cfg <- yaml::read_yaml("config/config.yml")

targets::tar_pipeline(
  tar_target(asset_returns, load_asset_returns(cfg$data$asset_returns_csv)),
  tar_target(baseline_weights, load_baseline_weights(cfg$data$baseline_weights_csv)),
  tar_target(macro_panel, load_macro_panel(cfg$data$fred_series)),
  tar_target(macro_signals, compute_macro_signals(macro_panel, cfg$regime$lookback_months)),
  tar_target(regime_labeled, label_regime(macro_signals, cfg$regime$growth_threshold, cfg$regime$inflation_threshold)),
  tar_target(regime_weights, allocation_from_regime(regime_labeled, cfg$allocation)),
  tar_target(strategy_returns, compute_strategy_returns(asset_returns, regime_weights, baseline_weights)),
  tar_target(perf_summary, summarize_performance(strategy_returns)),
  tar_target(regime_summary, summarize_by_regime(strategy_returns)),
  tar_target(save_strategy, write_output(strategy_returns, "data_processed/strategy_returns.csv"), format = "file"),
  tar_target(save_perf, write_output(perf_summary, "data_processed/performance_summary.csv"), format = "file"),
  tar_target(save_regime, write_output(regime_summary, "data_processed/regime_summary.csv"), format = "file")
)
