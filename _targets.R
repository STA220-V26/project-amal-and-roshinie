library(targets)
library(tarchetypes)

pkgs <- c(
  "janitor",
  "tidyverse",
  "data.table",
  "fs",
  "zip",
  "gt",
  "quarto",
  "broom"
)

invisible(lapply(pkgs, library, character.only = TRUE))

tar_option_set(
  packages = pkgs,
  format = "qs"
)

# Load functions
tar_source("R/functions.R")

# Download data
if (!fs::file_exists("data.zip")) {
  message("Downloading data.zip from GitHub")
  curl::curl_download(
    "https://github.com/STA220/cs/raw/refs/heads/main/data.zip",
    "data.zip",
    quiet = FALSE
  )
}

# Create data directory and extract files
if (!dir.exists("data")) dir.create("data")
unzip(
  zipfile = "data.zip",
  files = c("data-fixed/patients.csv", "data-fixed/conditions.csv"),
  exdir = "data"
)

list(
  # Load files
  tar_target(file_patients, "data/data-fixed/patients.csv", format = "file"),
  tar_target(file_conditions, "data/data-fixed/conditions.csv", format = "file"),

  # Clean and flag
  tar_target(data_patients, clean_patients(file_patients)),
  tar_target(data_flags, identify_conditions(file_conditions)),

  # Link datasets
  tar_target(data_final, left_join(data_patients, data_flags,
                                    by = c("id" = "patient")) %>%
               mutate(across(starts_with("has_"), ~replace_na(., FALSE)))),

  # Outputs
  tar_target(tab_demo, create_demographic_table(data_final)),
  tar_target(fig_prev, plot_income_prevalence(data_final)),
  tar_target(models, run_models(data_final)),

  # Target for Quarto presentation
  tar_quarto(presentation_slides, "docs/presentation.qmd"),

  # Target for report
  tar_quarto(report, "docs/report_roshinie.qmd")
)
