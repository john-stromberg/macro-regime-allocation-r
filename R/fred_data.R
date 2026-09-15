library(fredr)
library(dplyr)
library(tidyr)

load_macro_panel <- function(series_map) {
  key <- Sys.getenv("FRED_API_KEY")
  if (key == "") {
	warning("FRED_API_KEY not set; returning empty macro panel")
	return(tibble(date = as.Date(character()), growth_proxy = numeric(), inflation_proxy = numeric(), rates_proxy = numeric()))
  }

  fredr_set_key(key)

  long <- purrr::imap_dfr(series_map, function(series_id, label) {
	fredr(series_id = series_id) %>%
	  transmute(date = as.Date(date), series = label, value = value)
  })

  long %>%
	tidyr::pivot_wider(names_from = series, values_from = value) %>%
	arrange(date)
}
