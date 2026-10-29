macro_fixture <- function() {
  date <- seq(as.Date("2020-01-01"), as.Date("2024-12-01"), by = "month")
  t <- seq_along(date)
  dplyr::bind_rows(
	tibble::tibble(date = date, series = "growth_proxy", value = 100 * exp(0.002 * t + 0.025 * sin(t / 5))),
	tibble::tibble(date = date, series = "inflation_proxy", value = 100 * exp(0.003 * t + 0.006 * sin(t / 4))),
	tibble::tibble(date = date + 14, series = "rates_proxy", value = 2 + t / 100),
	tibble::tibble(date = date + 20, series = "rates_proxy", value = 4 + t / 100)
  )
}

baseline_fixture <- function() {
  tibble::tibble(asset = c("equity", "bonds", "commodities"), weight = c(0.4, 0.4, 0.2))
}

returns_fixture <- function() {
  tibble::tibble(date = as.Date(c("2024-01-31", "2024-02-29")),
	equity = c(0.1, 0), bonds = c(0, 0), commodities = c(0, 0))
}

tilts_fixture <- function() {
  tibble::tibble(date = as.Date(c("2023-11-30", "2023-12-31")), regime = "a",
	equity_w = 0.5, bonds_w = 0.3, commodities_w = 0.2)
}
