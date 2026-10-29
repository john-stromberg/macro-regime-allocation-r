test_that("both definitions distinguish growth level from direction", {
  x <- tibble::tibble(
	date = month_sequence(as.Date("2024-01-01"), as.Date("2024-05-01")),
	growth_level = c(0.02, 0.02, -0.01, -0.01, NA),
	growth_direction = c(-0.01, -0.01, 0.01, 0.01, NA),
	inflation_direction = c(-0.01, 0.01, -0.01, 0.01, NA)
  )
	level <- label_regime(x, persistence_months = 1)
  direction <- label_regime(x, definition = "growth_direction_inflation_direction", persistence_months = 1)
  expect_equal(level$regime, c("growth_expanding_inflation_falling", "growth_expanding_inflation_rising",
	"growth_contracting_inflation_falling", "growth_contracting_inflation_rising", NA))
  expect_equal(direction$regime, c("growth_decelerating_inflation_falling", "growth_decelerating_inflation_rising",
	"growth_accelerating_inflation_falling", "growth_accelerating_inflation_rising", NA))
  expect_error(label_regime(x, definition = "unknown"), "arg")
})

test_that("confirmation is causal and resets across missing observations", {
  regimes <- c("a", "a", "b", "a", "b", "b", NA, "b", "b")
  expect_equal(confirm_regimes(regimes, 2), c(NA, "a", "a", "a", "a", "b", NA, NA, "b"))
  expect_equal(confirm_regimes(regimes, 1), regimes)
  expect_equal(confirm_regimes(regimes[1:5], 2), confirm_regimes(regimes, 2)[1:5])
  expect_error(confirm_regimes(regimes, 0), "integer")
})

test_that("level and direction signals use calendar months and preserve warmup", {
  panel <- monthly_macro_panel(macro_fixture())
  out <- compute_macro_signals(panel, 12, 3)
  expect_true(all(is.na(out$growth_level[1:12])))
  expect_true(all(is.na(out$inflation_direction[1:15])))
  expect_equal(out$growth_level[13], panel$growth_proxy[13] / panel$growth_proxy[1] - 1)
  expect_equal(out$inflation_direction[16], out$inflation_level[16] - out$inflation_level[13])
  gapped <- compute_macro_signals(panel[-2, ], 12, 3)
  expect_equal(gapped$date, out$date)
  expect_true(is.na(gapped$growth_level[14]))
  expect_equal(gapped$growth_level[15], out$growth_level[15])
  expect_true(all(is.na(label_regime(out)$regime[1:16])))
  expect_error(compute_macro_signals(panel, 0), "integer")
  panel$growth_proxy[1] <- 0
  expect_error(compute_macro_signals(panel), "positive")
})

test_that("zero thresholds use the documented nonnegative branch", {
  x <- tibble::tibble(date = as.Date("2024-01-31"), growth_level = 0,
	growth_direction = 0, inflation_direction = 0)
  expect_equal(label_regime(x, persistence_months = 1)$regime, "growth_expanding_inflation_rising")
})
