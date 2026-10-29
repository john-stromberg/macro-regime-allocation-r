# macro-regime-allocation-r

Exploratory R research on macroeconomic regimes and rule-based portfolio tilts.
The pipeline combines FRED macro indicators with monthly asset-return CSVs and
compares net tilted returns with a baseline policy portfolio.

**Research status:** latest-vintage macro data are not point-in-time observations.
Fixed signal lags do not eliminate publication-timing uncertainty or revision bias.
The supplied January 2023–June 2024 asset-return sample is a demonstration without
documented investable instrument provenance, not evidence of regime efficacy.
Allocations and defaults are illustrative hypotheses, not investment recommendations.

## Quickstart

Run commands from the repository root.

1. Install R packages: `targets`, `dplyr`, `tidyr`, `readr`, `purrr`, `yaml`, and `fredr`.
2. For tests, install `testthat` and `withr`. For reports, install `knitr`, `rmarkdown`,
   and the R package `quarto`, plus the Quarto CLI.
3. Set the API key in your R session: `Sys.setenv(FRED_API_KEY = "your_key")`.
   Do not commit credentials. Missing credentials cause a clear error, not empty data.
4. Run `targets::tar_make()` to fetch current FRED data and produce outputs.
5. Run offline tests with `Rscript tests/testthat.R` or `source("tests/testthat.R")`.
6. Render with `quarto::quarto_render("reports/macro_regime_report.qmd")`.

Tests use deterministic synthetic macro fixtures, require neither `fredr` nor an API
key, and do not make network requests. Calendar calculations use base R; `slider`,
`lubridate`, `zoo`, and `PerformanceAnalytics` are not required.

For the full offline pipeline/report smoke test, run `Rscript tests/validate-workflow.R`
with the report dependencies installed. It runs both configured definitions, renders
both reports, and verifies CSV-content cache invalidation in a temporary copy. The
temporary outputs are removed; repository configuration, data, and production outputs
are left untouched.

## Economic definitions

Select `regime.definition` in `config/config.yml`:

| Definition | Growth dimension | Inflation dimension |
| --- | --- | --- |
| `growth_level_inflation_direction` (default) | Expanding/contracting: growth rate versus `growth_level_threshold` | Rising/falling: change in the inflation rate versus `inflation_threshold` |
| `growth_direction_inflation_direction` | Accelerating/decelerating: change in the growth rate versus `growth_direction_threshold` | Same inflation-direction measure |

Both definitions retain all four signal columns for inspection:

- `growth_level`: industrial-production level divided by its level `lookback_months`
  earlier, minus one. The default 12 months gives year-over-year growth.
- `inflation_level`: the analogous CPI change. This is inflation versus deflation,
  **not** the rising/falling inflation signal.
- `growth_direction` and `inflation_direction`: each level measure minus its value
  `direction_months` earlier (default 3 months). Positive inflation can be falling.
- Thresholds are decimal fractions. A direction value of `0.001` is an increase of
  0.1 percentage points in the measured growth/inflation rate. Equality uses the
  expanding/accelerating/rising branch; all default thresholds are zero.

Industrial production is a narrow growth proxy, not a comprehensive recession
classification. DGS10 is retained as rate context but drives neither regime model.
Each definition has a separately editable, named allocation matrix. Initial weights
are deliberately the same hypotheses under corresponding states, not optimized fits.

## Calendar and portfolio assumptions

- FRED observations are aggregated to arithmetic monthly means of available values,
  then placed on a complete month-end calendar. Monthly INDPRO/CPI observations retain
  their values; daily DGS10 becomes a monthly mean. Missing values are not forward-filled.
- `data.observation_start` defaults to 2000-01-01. A null `observation_end` requests
  data through the last completed calendar month. Supply sufficient pre-sample history
  for lookbacks, direction changes, confirmation, and the signal lag.
- `regime.persistence_months` defaults to 2. A label must occur consecutively to be
  confirmed. Pending switches retain the last confirmed label. Missing signals reset
  confirmation; missing/unconfirmed allocations explicitly use baseline weights.
- `backtest.signal_lag_months` defaults to 2 and must be at least 1. A January signal
  therefore applies to March's return with the default lag. This is an illustrative
  calendar delay, not a verified release-date schedule.
- All observed return months are retained. An entirely unmatched/unconfirmed sample
  fails instead of reporting a baseline-only strategy as successful analysis.
- Both portfolios rebalance monthly. Pre-trade holdings are the prior month's target
  weights after asset-return drift. Initial holdings equal the baseline, so initial
  strategy tilting incurs costs; initial baseline establishment costs are excluded.
- One-way turnover is half the sum of absolute weight changes. Costs equal turnover
  times `transaction_cost_bps / 10000` (default 10 bps). For example, turnover of 0.10
  costs 1 bp of portfolio value. Net return is `(1 - cost) * (1 + gross_return) - 1`.
- Costs are a proportional approximation without spreads, market impact, taxes, or
  liquidity constraints. Weight validation enforces a fully invested long-only
  portfolio, but no additional concentration cap or optimization is imposed.

Asset CSVs must contain `date`, `equity`, `bonds`, and `commodities`: one row per
consecutive month, finite decimal total returns greater than -1. Dates are normalized
to month-end; duplicate months and gaps are rejected. Weights must name each asset
exactly once, be nonnegative, and sum to one. Before using real data, document equity
coverage, bond credit/duration exposure, commodity construction, currency, and total-
return treatment. Do not mix price-only and total-return series.

## Outputs and interpretation

The pipeline writes five CSVs under `data_processed/`:

- `strategy_returns.csv`: applied signal dates, regimes, fallback flags, weights,
  gross/net returns, turnover, and costs.
- `performance_summary.csv`: cumulative and annualized net returns, annualized
  volatility and tracking error, information ratio, maximum drawdown, turnover, and costs.
- `regime_summary.csv`: sample counts/shares and descriptive monthly net-return moments.
- `macro_signals.csv`: full level/direction diagnostics and raw/confirmed labels.
- `run_settings.csv`: the economic definition, thresholds, portfolio assumptions,
  and exploratory data-vintage label used by the report.

`active_cum` is tilted cumulative return minus baseline cumulative return, not the
compound return of monthly differences. `relative_cum` is the terminal wealth ratio
minus one. Information ratio uses mean monthly net active return times 12 divided by
annualized tracking error. Undefined statistics are `NA`; drawdowns are negative
fractions and include initial wealth. Annualization assumes 12 monthly observations.
Regime summaries use the lagged regime actually applied, not the contemporaneous label.

The report loads these outputs and shows coverage, assumptions, net wealth/drawdowns,
and signal diagnostics. Short samples and synthetic validation data are flagged.
These are descriptive results, not significance tests or out-of-sample estimates.

Input CSVs and YAML configuration are tracked as `targets` file dependencies. FRED is
explicitly refreshed on every `tar_make()` run; latest-vintage revisions can therefore
change results. Preserve data snapshots and outputs externally for reproducible research.
Dependency locking, automated CI, and point-in-time vintage storage remain future work.

## Next research stage

Establish investable return provenance and a multi-cycle history; use historical
vintages and actual release dates; test tilt strength and costs with walk-forward
evaluation. Only then assess broader growth/inflation composites, financial-condition
overlays, and uncertainty estimates. Neither more indicators nor a longer sample
automatically establishes that the allocation rules add value.
