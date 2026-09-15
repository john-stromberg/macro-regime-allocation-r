library(readr)
library(dplyr)
library(lubridate)

load_asset_returns <- function(path) {
  read_csv(path, show_col_types = FALSE) %>%
	mutate(date = as_date(date)) %>%
	arrange(date)
}

load_baseline_weights <- function(path) {
  read_csv(path, show_col_types = FALSE)
}
