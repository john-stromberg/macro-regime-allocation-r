test_that("allocation weights sum to one", {
  regimes <- tibble::tibble(
	date = as.Date("2024-01-31"),
	regime = "growth_up_inflation_down"
  )
  cfg <- list(growth_up_inflation_down = c(0.5, 0.3, 0.2))
  out <- allocation_from_regime(regimes, cfg)
  s <- out$equity_w + out$bonds_w + out$commodities_w
  expect_equal(as.numeric(s), 1)
})
