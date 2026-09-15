test_that("regime labels are assigned", {
  x <- tibble::tibble(
	date = as.Date(c("2024-01-31", "2024-02-29")),
	growth_signal = c(0.02, -0.01),
	inflation_signal = c(-0.01, 0.02)
  )
  out <- label_regime(x, 0, 0)
  expect_true("regime" %in% names(out))
  expect_equal(nrow(out), 2)
})
