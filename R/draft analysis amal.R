# ============================================================
# STA220 - Data Project
# Anxiety, Addiction, and Income: Does Age Matter?
# Authors: Alma & Roshinie
# ============================================================

library(tidyverse)
library(janitor)

# ------------------------------------------------------------
# 1. LOAD DATA
# ------------------------------------------------------------

patients <- readr::read_csv(unz("data.zip", "data-fixed/patients.csv"))
conditions <- readr::read_csv(unz("data.zip", "data-fixed/conditions.csv"))

# ------------------------------------------------------------
# 2. DATA CLEANING
# ------------------------------------------------------------

# Remove empty rows and columns
patients <- janitor::remove_empty(patients, quiet = FALSE)
patients <- janitor::remove_constant(patients, quiet = FALSE)

# Remove duplicates
patients <- patients |> distinct(id, .keep_all = TRUE)

# Calculate age (reference: 2024-01-01)
patients <- patients |>
  mutate(age = as.integer(difftime(as.Date("2024-01-01"),
                                    birthdate,
                                    units = "days") / 365.25))

# Remove impossible ages
patients <- patients |> filter(age >= 0)

# Remove single extreme income outlier ($20)
patients <- patients |> filter(income >= 100)

# Keep only living adults (18+)
patients <- patients |> 
  filter(is.na(deathdate), age >= 18)

# Create age groups
patients <- patients |>
  mutate(
    age_group = ifelse(age < 35, "Under 35", "35 and over"),
    age_group = factor(age_group, levels = c("Under 35", "35 and over"))
  )

# How many patients remain?
nrow(patients)

# ------------------------------------------------------------
# 3. CREATE BINARY INDICATORS
# ------------------------------------------------------------

# SNOMED code for severe anxiety
anxiety_code <- 80583007

# SNOMED codes for addiction disorders
# Excluded: 47318007 (Drug-induced neutropenia - not an addiction)
addiction_codes <- c(6525002, 10939881000119104, 361055000, 5602001, 7200002)

# Create anxiety indicator
anxiety <- conditions |>
  filter(code == anxiety_code) |>
  distinct(patient) |>
  mutate(anxiety = 1)

# Create addiction indicator
addiction <- conditions |>
  filter(code %in% addiction_codes) |>
  distinct(patient) |>
  mutate(addiction = 1)

# ------------------------------------------------------------
# 4. JOIN AND PREPARE DATA
# ------------------------------------------------------------

data <- patients |>
  left_join(anxiety, by = c("id" = "patient")) |>
  left_join(addiction, by = c("id" = "patient")) |>
  mutate(
    anxiety = replace_na(anxiety, 0),
    addiction = replace_na(addiction, 0),
    income_log = log(income),
    group = case_when(
      anxiety == 0 & addiction == 0 ~ "Neither",
      anxiety == 1 & addiction == 0 ~ "Anxiety only",
      anxiety == 0 & addiction == 1 ~ "Addiction only",
      anxiety == 1 & addiction == 1 ~ "Both"
    ),
    group = factor(group, levels = c("Neither", "Anxiety only",
                                      "Addiction only", "Both"))
  )

# ------------------------------------------------------------
# 5. DESCRIPTIVE ANALYSIS
# ------------------------------------------------------------

# Prevalence of anxiety and addiction by age group and gender
data |>
  group_by(age_group, gender) |>
  summarise(
    n = n(),
    anxiety_pct = round(mean(anxiety) * 100, 1),
    addiction_pct = round(mean(addiction) * 100, 1),
    .groups = "drop"
  )

# ------------------------------------------------------------
# 6. VISUALIZATIONS
# ------------------------------------------------------------

# Plot 1: Log income distribution by condition group and age group
ggplot(data, aes(x = group, y = income_log, fill = group)) +
  geom_boxplot() +
  facet_wrap(~ age_group) +
  labs(
    title = "Log Income by Anxiety and Addiction Status",
    subtitle = "Stratified by Age Group",
    x = "Patient Group",
    y = "Log(Income)"
  ) +
  theme_minimal() +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))

# Plot 2: Prevalence by age group and gender
data |>
  group_by(age_group, gender) |>
  summarise(
    anxiety_pct = mean(anxiety) * 100,
    addiction_pct = mean(addiction) * 100,
    .groups = "drop"
  ) |>
  pivot_longer(cols = c(anxiety_pct, addiction_pct),
               names_to = "condition",
               values_to = "prevalence") |>
  mutate(condition = recode(condition,
                             "anxiety_pct" = "Anxiety",
                             "addiction_pct" = "Addiction")) |>
  ggplot(aes(x = age_group, y = prevalence, fill = gender)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~ condition) +
  labs(
    title = "Prevalence of Anxiety and Addiction by Age Group and Gender",
    x = "Age Group",
    y = "Prevalence (%)",
    fill = "Gender"
  ) +
  theme_minimal()

# ------------------------------------------------------------
# 7. STATISTICAL MODELS
# ------------------------------------------------------------

# Model 1: Addiction ~ income + gender in adults 35+
# Income is only significant in this age group
data_older <- data |> filter(age_group == "35 and over")

model_addiction_older <- glm(addiction ~ income_log + gender,
                              data = data_older,
                              family = binomial)

cat("\n=== ADDICTION MODEL - 35 AND OVER ===\n")
exp(coef(model_addiction_older))
exp(confint(model_addiction_older))

# Model 2: Anxiety ~ gender + age group
# Gender is the only consistent predictor of anxiety
model_anxiety <- glm(anxiety ~ gender + age_group,
                     data = data,
                     family = binomial)

cat("\n=== ANXIETY MODEL - ALL ADULTS ===\n")
exp(coef(model_anxiety))
exp(confint(model_anxiety))