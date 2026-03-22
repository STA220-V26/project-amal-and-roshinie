# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) 

# Set target options:
pkgs <- c(
  "janitor", # data cleaning
  "labelled", # labeling data
  "pointblank", # data validation and exploration
  "rvest", # get data from web pages
  "tidyverse", # Data management
  "data.table", # fast data management
  "fs", # to work wit hthe file system
  "zip", # manipulate zip files
  "gt", #for nice tables
  "quarto"
)

invisible(lapply(pkgs, library, character.only = TRUE))

# Set target options:
tar_option_set(
  # Packages that your targets need for their tasks:
  packages = pkgs,
  format = "qs", # Default storage format. qs (which is actually qs2) is fast.
)

# Run the R scripts stored in the R/ folder where your have stored your custom functions:
tar_source("draft-roshinie.R")
# tar_source("other_functions.R") # Source other scripts as needed.


# We first download the data health care data of interest
if (!fs::file_exists("data.zip")) {
  message("Downloading data.zip from GitHub")
  curl::curl_download(
    "https://github.com/STA220/cs/raw/refs/heads/main/data.zip",
    "data.zip",
    quiet = FALSE
  )
}

#Create data directory
if (!dir.exists("data")) dir.create("data")

#Add the needed data files to the directory
unzip(
  zipfile = "data.zip", 
  files = c("data-fixed/patients.csv", "data-fixed/conditions.csv"),
  exdir = "data"
)

list(
  # Load Files
  tar_target(file_patients, "data/data-fixed/patients.csv", format = "file"),
  tar_target(file_conditions, "data/data-fixed/conditions.csv", format = "file"),
  
  # Clean and Flag
  tar_target(data_patients, clean_patients(file_patients)),
  tar_target(data_flags, identify_conditions(file_conditions)),
  
  # Link
  tar_target(data_final, left_join(data_patients, data_flags, by = c("id" = "patient")) %>% 
               mutate(across(starts_with("has_"), ~replace_na(., FALSE)))),
  
  # Outputs for Report
  tar_target(tab_demo, create_demographic_table(data_final)),
  tar_target(fig_prev, plot_income_prevalence(data_final)),
  tar_target(fig_interact, plot_demographic_interaction(data_final)),
  
  # Render Quarto for the presentation
  tar_quarto(presentation_slides, "docs/presentation.qmd")
)