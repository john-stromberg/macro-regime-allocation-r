test_that("performance summary includes active metrics", {
  x <- tibble::tibble(
	date = as.Date(c("2024-01-31", "2024-02-29")),
	regime = c("a", "b"),
	baseline_return = c(0.01, 0.00),
	tilted_return = c(0.015, -0.002),
	active_return = c(0.005, -0.002)
  )
  out <- summarize_performance(x)
  expect_true(all(c("active_cum", "active_mean", "active_vol") %in% names(out)))
})
