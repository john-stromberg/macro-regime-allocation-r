test_that("performance summary computes wealth differences and risk numerically", {
  x <- tibble::tibble(
	date = as.Date(c("2024-01-31", "2024-02-29")),
	regime = c("a", "b"),
	baseline_return = c(0.01, 0.00),
	tilted_return = c(0.015, -0.002),
	active_return = c(0.005, -0.002)
  )
  out <- summarize_performance(x)
	expect_equal(out$baseline_cum, 0.01)
  expect_equal(out$tilted_cum, 1.015 * 0.998 - 1)
  expect_equal(out$active_cum, 1.015 * 0.998 - 1.01)
  expect_equal(out$relative_cum, (1.015 * 0.998) / 1.01 - 1)
  expect_equal(out$baseline_annualized_return, 1.01^6 - 1)
  expect_equal(out$tracking_error, sd(x$active_return) * sqrt(12))
  expect_equal(out$information_ratio, mean(x$active_return) * 12 / out$tracking_error)
  expect_equal(out$tilted_max_drawdown, -0.002)
  expect_equal(maximum_drawdown(c(-0.1, 0.05)), -0.1)
  expect_equal(summarize_performance(x[2:1, ])$tilted_max_drawdown, -0.002)
  expect_equal(summarize_by_regime(x)$obs, c(1L, 1L))
  expect_equal(summarize_by_regime(x)$share, c(0.5, 0.5))
})

test_that("zero tracking error and single observations are explicit", {
  x <- tibble::tibble(date = as.Date(c("2024-01-31", "2024-02-29")),
	regime = "a", baseline_return = 0.01, tilted_return = 0.01, active_return = 0)
  expect_true(is.na(summarize_performance(x)$information_ratio))
  expect_true(is.na(summarize_performance(x[1, ])$tracking_error))
  expect_true(is.na(summarize_by_regime(x[1, ])$vol_active))
  expect_error(summarize_performance(x[FALSE, ]), "valid dates")
  x$tilted_return[1] <- NA_real_
  expect_error(summarize_performance(x), "finite returns")
})
