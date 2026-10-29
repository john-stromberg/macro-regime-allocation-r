test_that("mixed-frequency macro observations use complete monthly means", {
  long <- macro_fixture()
  panel <- monthly_macro_panel(long)
  expect_equal(nrow(panel), 60)
  expect_equal(panel$date[1], as.Date("2020-01-31"))
  expect_equal(panel$rates_proxy[1], 3.01)
  expect_equal(panel$growth_proxy[1], long$value[1])
  missing_month <- month_end(long$date) == as.Date("2020-02-29")
  gapped <- monthly_macro_panel(long[!missing_month, ])
  expect_equal(gapped$date, panel$date)
  expect_true(is.na(gapped$growth_proxy[2]))
  long$value[long$series == "rates_proxy"] <- NA_real_
  expect_true(all(is.na(monthly_macro_panel(long)$rates_proxy)))
  expect_error(monthly_macro_panel(dplyr::bind_rows(long, long[1, ])), "unique")
})

test_that("CSV ingestion rejects malformed returns and baseline allocations", {
  path <- tempfile(fileext = ".csv")
  withr::defer(unlink(path))
  returns <- returns_fixture()
  returns$date <- as.Date(c("2024-01-01", "2024-02-01"))
  readr::write_csv(returns, path)
  expect_equal(load_asset_returns(path)$date, as.Date(c("2024-01-31", "2024-02-29")))
  returns$date[2] <- returns$date[1]
  readr::write_csv(returns, path)
  expect_error(load_asset_returns(path), "one row")
  returns <- returns_fixture()
  returns$equity[1] <- NA_real_
  expect_error(validate_asset_returns(returns), "finite decimal")
  returns$equity[1] <- -1
  expect_error(validate_asset_returns(returns), "greater than -1")
  returns <- returns_fixture()
  returns$date[2] <- as.Date("2024-03-31")
  expect_error(validate_asset_returns(returns), "consecutive")
  expect_error(validate_asset_returns(returns[, c("date", "equity")]), "missing columns")
  weights <- baseline_fixture()
  weights$weight[1] <- 0.5
  readr::write_csv(weights, path)
  expect_error(load_baseline_weights(path), "summing to one")
  weights <- baseline_fixture()
  weights$asset[2] <- "equity"
  expect_error(baseline_vector(weights), "must name")
})

test_that("missing FRED credentials fail before any network request", {
  withr::local_envvar(FRED_API_KEY = NA_character_)
  expect_error(load_macro_panel(list()), "Set FRED_API_KEY")
})
