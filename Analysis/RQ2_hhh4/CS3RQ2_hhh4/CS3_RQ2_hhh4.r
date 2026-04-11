rm(list = ls())

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(janitor)
  library(surveillance)
})

# =========================
# User settings
# =========================
data_path <- "../../../Data/AllNationsCombined.csv"
output_dir <- "hhh4_exports"
dir.create(output_dir, showWarnings = FALSE)

selected_countries <- c(
  "Australia", "Brazil", "Canada", "China",
  "South Africa", "United Kingdom", "United States"
)

# Initial training size in weeks for one-step-ahead evaluation
# Weekly panel will have roughly 82 weeks in this dataset.
initial_train_weeks <- 55

# =========================
# Helper functions
# =========================
safe_rmse <- function(x) {
  sqrt(mean(x, na.rm = TRUE))
}

safe_mae <- function(x) {
  mean(x, na.rm = TRUE)
}

to_long_osa <- function(osa_obj, model_name, time_index_to_week_end) {
  pred_mat <- as.matrix(osa_obj$pred)
  obs_mat <- as.matrix(osa_obj$observed)

  pred_df <- as.data.frame(pred_mat)
  obs_df <- as.data.frame(obs_mat)

  pred_df$pred_time_index <- as.integer(rownames(pred_df))
  obs_df$pred_time_index <- as.integer(rownames(obs_df))

  pred_long <- pred_df %>%
    pivot_longer(
      cols = -pred_time_index,
      names_to = "country",
      values_to = "forecast"
    )

  obs_long <- obs_df %>%
    pivot_longer(
      cols = -pred_time_index,
      names_to = "country",
      values_to = "actual"
    )

  out <- pred_long %>%
    left_join(obs_long, by = c("pred_time_index", "country")) %>%
    mutate(
      date = as.Date(time_index_to_week_end[pred_time_index]),
      model = model_name,
      error = actual - forecast,
      abs_error = abs(error),
      sq_error = error^2
    ) %>%
    select(date, pred_time_index, country, model, actual, forecast, error, abs_error, sq_error)

  out
}

# =========================
# Read and clean daily data
# =========================
raw_df <- read_csv(data_path, show_col_types = FALSE)
raw_df <- clean_names(raw_df)

covid_df <- raw_df %>%
  transmute(
    country = case_when(
      country_name == "UNITED STATES OF AMERICA" ~ "United States",
      country_name == "UNITED KINGDOM" ~ "United Kingdom",
      country_name == "SOUTH AFRICA" ~ "South Africa",
      country_name == "AUSTRALIA" ~ "Australia",
      country_name == "BRAZIL" ~ "Brazil",
      country_name == "CANADA" ~ "Canada",
      country_name == "CHINA" ~ "China",
      TRUE ~ str_to_title(country_name)
    ),
    date = as.Date(date),
    cases = as.numeric(count_value),
    population = readr::parse_number(as.character(total_population))
  ) %>%
  filter(country %in% selected_countries) %>%
  arrange(country, date)

# Balanced daily panel
full_grid <- expand_grid(
  country = selected_countries,
  date = seq(min(covid_df$date), max(covid_df$date), by = "day")
)

panel_df <- full_grid %>%
  left_join(covid_df, by = c("country", "date")) %>%
  arrange(country, date) %>%
  group_by(country) %>%
  mutate(
    population = zoo::na.locf(population, na.rm = FALSE),
    population = zoo::na.locf(population, fromLast = TRUE, na.rm = FALSE),
    cases = zoo::na.approx(cases, na.rm = FALSE)
  ) %>%
  ungroup()

# =========================
# Aggregate to weekly counts
# =========================
# Use week ending Sunday for consistency.
weekly_df <- panel_df %>%
  mutate(week_end = ceiling_date(date, unit = "week", week_start = 1) - days(1)) %>%
  group_by(country, week_end) %>%
  summarise(
    weekly_cases = sum(cases, na.rm = TRUE),
    population = first(population),
    .groups = "drop"
  ) %>%
  arrange(country, week_end)

# Balanced weekly panel
all_weeks <- seq(min(weekly_df$week_end), max(weekly_df$week_end), by = "week")

weekly_full <- expand_grid(
  country = selected_countries,
  week_end = all_weeks
) %>%
  left_join(weekly_df, by = c("country", "week_end")) %>%
  arrange(country, week_end) %>%
  group_by(country) %>%
  mutate(
    population = zoo::na.locf(population, na.rm = FALSE),
    population = zoo::na.locf(population, fromLast = TRUE, na.rm = FALSE),
    weekly_cases = replace_na(weekly_cases, 0)
  ) %>%
  ungroup()

# Wide matrix for sts object
obs_matrix <- weekly_full %>%
  select(week_end, country, weekly_cases) %>%
  pivot_wider(names_from = country, values_from = weekly_cases) %>%
  arrange(week_end)

week_end_vec <- obs_matrix$week_end
obs_mat <- obs_matrix %>%
  select(all_of(selected_countries)) %>%
  as.matrix()

mode(obs_mat) <- "numeric"

# =========================
# Build sts object
# =========================
week_end_vec <- as.Date(week_end_vec)
start_date <- min(week_end_vec)

start_year <- as.integer(format(start_date, "%G"))
start_week <- as.integer(format(start_date, "%V"))

sts_obj <- sts(
  observed = obs_mat,
  start = c(start_year, start_week),
  frequency = 52,
  epoch = week_end_vec
)

# =========================
# Weight matrix for multivariate neighborhood effect
# =========================
K <- ncol(obs_mat)
W <- matrix(1, nrow = K, ncol = K)
diag(W) <- 0
W <- W / rowSums(W)
colnames(W) <- selected_countries
rownames(W) <- selected_countries

# =========================
# Define two hhh4 models
# =========================
# Model 1: within-country only
control_within <- list(
  end = list(f = addSeason2formula(~1, period = 52)),
  ar = list(f = ~1),
  family = "NegBin1"
)

# Model 2: full model with neighborhood spillover
control_full <- list(
  end = list(f = addSeason2formula(~1, period = 52)),
  ar = list(f = ~1),
  ne = list(f = ~1, weights = W),
  family = "NegBin1"
)

# =========================
# Fit baseline models on the initial training subset
# =========================
subset_initial <- 1:initial_train_weeks

fit_within <- hhh4(
  stsObj = sts_obj,
  control = modifyList(control_within, list(subset = subset_initial))
)

fit_full <- hhh4(
  stsObj = sts_obj,
  control = modifyList(control_full, list(subset = subset_initial))
)

# =========================
# Expanding-window one-step-ahead predictions
# =========================
# oneStepAhead predicts tp[1]+1, ..., tp[2]+1
# so to begin forecasting after week initial_train_weeks,
# set tp = initial_train_weeks:(n_weeks - 1)
n_weeks <- nrow(obs_mat)
tp_range <- c(initial_train_weeks, n_weeks - 1)

osa_within <- oneStepAhead(
  result = fit_within,
  tp = tp_range,
  type = "rolling",
  which.start = "final",
  keep.estimates = FALSE,
  verbose = FALSE
)

osa_full <- oneStepAhead(
  result = fit_full,
  tp = tp_range,
  type = "rolling",
  which.start = "final",
  keep.estimates = FALSE,
  verbose = FALSE
)

# =========================
# Convert forecasts to long tables
# =========================
forecast_within_long <- to_long_osa(
  osa_obj = osa_within,
  model_name = "hhh4_within",
  time_index_to_week_end = week_end_vec
)

forecast_full_long <- to_long_osa(
  osa_obj = osa_full,
  model_name = "hhh4_full",
  time_index_to_week_end = week_end_vec
)

hhh4_forecasts_long <- bind_rows(
  forecast_within_long,
  forecast_full_long
) %>%
  arrange(model, country, date)

# =========================
# Summaries
# =========================
hhh4_summary_by_country <- hhh4_forecasts_long %>%
  group_by(country, model) %>%
  summarise(
    n_forecasts = sum(!is.na(forecast)),
    rmse = safe_rmse(sq_error),
    mae = safe_mae(abs_error),
    .groups = "drop"
  ) %>%
  arrange(country, model)

hhh4_summary_overall <- hhh4_forecasts_long %>%
  group_by(model) %>%
  summarise(
    n_forecasts = sum(!is.na(forecast)),
    rmse = safe_rmse(sq_error),
    mae = safe_mae(abs_error),
    .groups = "drop"
  ) %>%
  arrange(model)

# =========================
# Export CSVs for Python / Jupyter
# =========================
write_csv(hhh4_forecasts_long, file.path(output_dir, "hhh4_forecasts_long.csv"))
write_csv(hhh4_summary_by_country, file.path(output_dir, "hhh4_summary_by_country.csv"))
write_csv(hhh4_summary_overall, file.path(output_dir, "hhh4_summary_overall.csv"))

# Also export metadata that may help with joins/checks
metadata_df <- tibble(
  metric = c("n_weeks_total", "initial_train_weeks"),
  value = c(n_weeks, initial_train_weeks)
)

write_csv(metadata_df, file.path(output_dir, "hhh4_metadata.csv"))

cat("\nExport completed.\n")
cat("Files written to:", normalizePath(output_dir), "\n")
cat("\nCountry-level summary:\n")
print(hhh4_summary_by_country)
cat("\nOverall summary:\n")
print(hhh4_summary_overall)

# =====================

cat("\n=== In-sample fit diagnostics ===\n")

cat("\nfit_within coefficients:\n")
print(coef(fit_within))

cat("\nfit_full coefficients:\n")
print(coef(fit_full))

cat("\nfit_within logLik / AIC:\n")
print(logLik(fit_within))
print(AIC(fit_within))

cat("\nfit_full logLik / AIC:\n")
print(logLik(fit_full))
print(AIC(fit_full))

cat("\n=== Check whether predictions are identical ===\n")
pred_diff <- as.matrix(osa_full$pred) - as.matrix(osa_within$pred)

cat("\nMaximum absolute difference in predictions:\n")
print(max(abs(pred_diff), na.rm = TRUE))

cat("\nSummary of prediction differences:\n")
print(summary(as.vector(pred_diff)))