test_that("allocation validates named assets and preserves missing regimes", {
  regimes <- tibble::tibble(date = as.Date(c("2023-11-30", "2023-12-31")), regime = c("a", NA))
  cfg <- list(a = c(commodities = 0.2, equity = 0.5, bonds = 0.3))
  out <- allocation_from_regime(regimes, cfg)
	expect_equal(out$equity_w, c(0.5, NA))
  expect_equal(out$bonds_w, c(0.3, NA))
  expect_equal(out$equity_w[1] + out$bonds_w[1] + out$commodities_w[1], 1)
  expect_error(allocation_from_regime(regimes, list(a = c(0.5, 0.3, 0.2))), "must name")
  expect_error(allocation_from_regime(regimes, list(b = cfg$a)), "missing a regime")
  expect_error(validate_weight_vector(c(equity = 1.2, bonds = -0.3, commodities = 0.1)), "nonnegative")
})

test_that("calendar-lagged returns include drift-aware costs on both portfolios", {
  returns <- returns_fixture()
  tilts <- tilts_fixture()
  out <- compute_strategy_returns(returns, tilts, baseline_fixture(), 2, 10)
  expect_equal(out$date, returns$date)
  expect_equal(out$signal_date, tilts$date)
  expect_equal(out$baseline_gross_return, c(0.04, 0))
  expect_equal(out$tilted_gross_return, c(0.05, 0))
  expect_equal(out$tilted_turnover[1], 0.1)
  expect_equal(out$baseline_turnover[1], 0)
  expect_equal(out$tilted_cost[1], 0.0001)
  expect_equal(out$tilted_return[1], 1.05 * (1 - 0.0001) - 1)
  expect_equal(out$baseline_turnover[2], sum(abs(c(0.4, 0.4, 0.2) - c(0.44, 0.4, 0.2) / 1.04)) / 2)
  expect_equal(out$tilted_turnover[2], sum(abs(c(0.5, 0.3, 0.2) - c(0.55, 0.3, 0.2) / 1.05)) / 2)
  free <- compute_strategy_returns(returns, tilts, baseline_fixture(), 2, 0)
  expect_equal(free$baseline_return, free$baseline_gross_return)
  expect_equal(free$tilted_return, free$tilted_gross_return)
  expect_equal(out$active_return, out$tilted_return - out$baseline_return)
  expect_error(compute_strategy_returns(returns, tilts, baseline_fixture(), 0), "integer")
  expect_error(compute_strategy_returns(returns, tilts, baseline_fixture(), 2, -1), "transaction_cost_bps")
})

test_that("missing signals use baseline without silently dropping return months", {
  tilts <- tilts_fixture()
  tilts$regime[1] <- NA_character_
  out <- compute_strategy_returns(returns_fixture(), tilts, baseline_fixture())
  expect_equal(out$regime, c("baseline_fallback", "a"))
  expect_equal(out$used_baseline_fallback, c(TRUE, FALSE))
  expect_equal(out$tilted_return[1], out$baseline_return[1])
  expect_equal(out$equity_w[1], 0.4)
  tilts$regime[] <- NA_character_
  expect_error(compute_strategy_returns(returns_fixture(), tilts, baseline_fixture()), "No confirmed")
})

test_that("later weights cannot alter earlier portfolio returns", {
  tilts <- tilts_fixture()
  before <- compute_strategy_returns(returns_fixture(), tilts, baseline_fixture())
  tilts$equity_w[2] <- 0.2
  tilts$bonds_w[2] <- 0.6
  after <- compute_strategy_returns(returns_fixture(), tilts, baseline_fixture())
  expect_equal(before[1, ], after[1, ])
  expect_equal(shift_month(as.Date(c("2023-12-31", "2024-01-31")), 2),
	as.Date(c("2024-02-29", "2024-03-31")))
})
