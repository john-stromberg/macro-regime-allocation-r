validate_workflow <- function() {
  root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  stopifnot(file.exists(file.path(root, "_targets.R")))
  sandbox <- tempfile("macro-workflow-")
  dir.create(sandbox)
  withr::defer(unlink(sandbox, recursive = TRUE))
  stopifnot(all(file.copy(file.path(root, c("R", "config", "data_raw", "reports")),
	sandbox, recursive = TRUE)))
  stopifnot(file.copy(file.path(root, "_targets.R"), sandbox))
  stopifnot(file.copy(file.path(root, "tests", "testthat", "helper-fixtures.R"),
	file.path(sandbox, "fixture.R")))
  withr::local_dir(sandbox)
  withr::local_envvar(FRED_API_KEY = NA_character_)

  script <- "_targets_validation.R"
  writeLines(c(
	"pipeline <- source('_targets.R', local = TRUE)$value",
	"source('fixture.R', local = TRUE)",
	"load_macro_panel <- function(...) {",
	"  panel <- monthly_macro_panel(macro_fixture())",
	"  panel$data_vintage <- 'synthetic_fixture'",
	"  panel",
	"}",
	"pipeline"
  ), script)
  targets::tar_validate(script = script)
  cfg <- yaml::read_yaml("config/config.yml")
  outputs <- file.path("data_processed", c("strategy_returns.csv", "performance_summary.csv",
	"regime_summary.csv", "macro_signals.csv", "run_settings.csv"))
  for (definition in names(cfg$allocation)) {
	cfg$regime$definition <- definition
	yaml::write_yaml(cfg, "config/config.yml")
	targets::tar_make(script = script, reporter = "balanced")
	stopifnot(all(file.exists(outputs)))
	settings <- readr::read_csv(outputs[5], show_col_types = FALSE)
	strategy <- readr::read_csv(outputs[1], show_col_types = FALSE)
	performance <- readr::read_csv(outputs[2], show_col_types = FALSE)
	stopifnot(settings$regime_definition == definition,
	  settings$data_vintage == "synthetic_fixture", nrow(strategy) == 18,
	  performance$periods == 18, all(strategy$regime_definition == definition))
	quarto::quarto_render("reports/macro_regime_report.qmd", quiet = TRUE)
	html_path <- "reports/macro_regime_report.html"
	stopifnot(file.exists(html_path))
	html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
	stopifnot(grepl("SYNTHETIC FIXTURE", html, fixed = TRUE),
	  grepl(definition, html, fixed = TRUE),
	  grepl("Short sample", html, fixed = TRUE))
	message("Validated pipeline and rendered report: ", definition)
  }

  before <- targets::tar_read(asset_returns)
  csv <- readr::read_csv(cfg$data$asset_returns_csv, show_col_types = FALSE)
  csv$equity[1] <- csv$equity[1] + 0.001
  readr::write_csv(csv, cfg$data$asset_returns_csv)
	targets::tar_make(script = script, reporter = "balanced")
  after <- targets::tar_read(asset_returns)
  stopifnot(isTRUE(all.equal(after$equity[1], before$equity[1] + 0.001)))
  message("Validated CSV content invalidation. All sandbox outputs will be removed.")
}

validate_workflow()
