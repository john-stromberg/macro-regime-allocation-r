# macro-regime-allocation-r

R project for macro regime classification and allocation tilts with analytics, report, and tests.

## Analytical question

How should portfolio weights tilt across assets when inflation, growth, and rates indicate different macro regimes?

## Recommended data approach

- **FRED + CSV blend**
  - FRED: macro indicators (growth, inflation, policy/rates)
  - CSV: asset return series and baseline policy weights

## Scope (v1)

- Regime labeling from macro indicators
- Regime-conditional return/risk summary
- Rule-based allocation tilt engine
- Backtest of tilted vs baseline allocation
- Decision-oriented Quarto report
- Test coverage for core transformations

## Quickstart

1. Install packages: `targets`, `tidyverse`, `lubridate`, `fredr`, `slider`, `zoo`, `PerformanceAnalytics`, `yaml`, `quarto`, `testthat`
2. Set API key: `Sys.setenv(FRED_API_KEY = "your_key")`
3. Run pipeline: `targets::tar_make()`
4. Run tests: `source("tests/testthat.R")`
5. Render report: `quarto::quarto_render("reports/macro_regime_report.qmd")`
