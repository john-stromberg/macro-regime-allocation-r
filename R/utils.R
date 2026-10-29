library(readr)

month_end <- function(date) {
	first <- as.Date(format(as.Date(date), "%Y-%m-01"))
  as.Date(format(first + 32, "%Y-%m-01")) - 1
}

shift_month <- function(date, months) {
	date <- as.Date(date)
  out <- rep(as.Date(NA), length(date))
  valid <- !is.na(date)
  index <- as.integer(format(date[valid], "%Y")) * 12 +
	as.integer(format(date[valid], "%m")) - 1 + months
  out[valid] <- month_end(as.Date(sprintf("%04d-%02d-01", index %/% 12, index %% 12 + 1)))
  out
}

month_sequence <- function(from, to) {
	month_end(seq(as.Date(format(from, "%Y-%m-01")),
				 as.Date(format(to, "%Y-%m-01")), by = "month"))
}

require_columns <- function(df, columns, label) {
  missing <- setdiff(columns, names(df))
  if (length(missing)) {
	stop(label, " is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

validate_count <- function(value, label, minimum = 1) {
  if (!is.numeric(value) || length(value) != 1 || !is.finite(value) ||
	  value < minimum || value != floor(value)) {
	stop(label, " must be an integer >= ", minimum, call. = FALSE)
  }
}

validate_monthly <- function(df, label, consecutive = TRUE) {
  require_columns(df, "date", label)
  if (!nrow(df) || !inherits(df$date, "Date") || anyNA(df$date) ||
	  anyDuplicated(month_end(df$date))) {
	stop(label, " must have valid dates and exactly one row per observed month", call. = FALSE)
  }
  if (consecutive && nrow(df) != length(month_sequence(min(df$date), max(df$date)))) {
	stop(label, " must contain consecutive months", call. = FALSE)
  }
}

validate_weight_vector <- function(weights, label = "Weights") {
  assets <- c("equity", "bonds", "commodities")
  weights <- unlist(weights)
  if (!is.numeric(weights) || length(weights) != length(assets) ||
	  is.null(names(weights)) || anyDuplicated(names(weights)) ||
	  !setequal(names(weights), assets) || any(!is.finite(weights)) ||
	  any(weights < 0) || abs(sum(weights) - 1) > 1e-8) {
	stop(label, " must name equity, bonds, commodities with nonnegative weights summing to one", call. = FALSE)
  }
  weights[assets]
}

write_output <- function(df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write_csv(df, path)
  invisible(path)
}
