library(dplyr)
library(tidyr)

monthly_macro_panel <- function(long) {
  require_columns(long, c("date", "series", "value"), "Macro observations")
  if (!nrow(long) || !inherits(long$date, "Date") || anyNA(long$date) ||
	  !is.numeric(long$value) || any(is.infinite(long$value)) ||
	  anyDuplicated(long[c("date", "series")])) {
	stop("Macro observations require unique series/date pairs and numeric values", call. = FALSE)
  }
  required <- c("growth_proxy", "inflation_proxy", "rates_proxy")
  if (anyNA(long$series) || !setequal(unique(long$series), required)) {
	stop("Macro observations must include growth_proxy, inflation_proxy, rates_proxy", call. = FALSE)
  }
  monthly <- long %>%
	mutate(date = month_end(date)) %>%
	group_by(date, series) %>%
	summarise(value = if (all(is.na(value))) NA_real_ else mean(value, na.rm = TRUE), .groups = "drop") %>%
	pivot_wider(names_from = series, values_from = value)
  tibble(date = month_sequence(min(monthly$date), max(monthly$date))) %>%
	left_join(monthly, by = "date") %>%
	arrange(date)
}

load_macro_panel <- function(series_map, observation_start = as.Date("2000-01-01"),
							 observation_end = NULL) {
  key <- Sys.getenv("FRED_API_KEY")
  if (key == "") {
	stop("Set FRED_API_KEY to fetch exploratory latest-vintage macro data", call. = FALSE)
  }
  if (is.null(observation_end)) {
	observation_end <- as.Date(format(Sys.Date(), "%Y-%m-01")) - 1
  }
  observation_start <- as.Date(observation_start)
  observation_end <- as.Date(observation_end)
  if (length(observation_start) != 1 || length(observation_end) != 1 ||
	  is.na(observation_start) || is.na(observation_end) || observation_start > observation_end) {
	stop("FRED observation dates must specify a valid ordered range", call. = FALSE)
  }

	fredr::fredr_set_key(key)
  long <- purrr::imap_dfr(series_map, function(series_id, label) {
	fredr::fredr(series_id = series_id, observation_start = observation_start,
				 observation_end = observation_end) %>%
	  transmute(date = as.Date(date), series = label, value = value)
  })

	monthly_macro_panel(long) %>%
	mutate(data_vintage = "latest_vintage_exploratory")
}
