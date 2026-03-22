library(tidyverse)
library(data.table)
library(janitor)
library(gt) 

# 1. Clean Patients and add Demographics
clean_patients <- function(path) {
  read_csv(path, show_col_types = FALSE) %>%
    mutate(
      birthdate = as.Date(birthdate),
      # Calculate age (approximate)
      age = as.numeric(difftime(Sys.Date(), birthdate, units = "weeks")) / 52.25,
      age_group = ifelse(age < 45, "Younger Adult (<45)", "Older Adult (45+)"),
      # Create Income Quartiles for comparison
      income_quartile = ntile(income, 4),
      income_label = factor(income_quartile, levels = 1:4, 
                            labels = c("Lowest", "Lower-Mid", "Upper-Mid", "Highest"))
    ) %>%
    select(id, age, age_group, gender, income, income_label)
}

# 2. Flag Conditions
identify_conditions <- function(path) {
  raw_conditions <- read_csv(path, show_col_types = FALSE)
  
  # Define keywords based on data inspection
  substance_keywords <- "alcohol|drug abuse|drug abuse|opioid|misuses drugs"
  
  raw_conditions %>%
    group_by(patient) %>%
    summarise(
      has_anxiety = any(str_detect(description, "Severe anxiety"), na.rm = TRUE),
      has_substance_use = any(str_detect(description, regex(substance_keywords, ignore_case = TRUE)) & 
                              !str_detect(description, "neutropenia"), na.rm = TRUE)
    ) %>%
    ungroup()
}

# 3. Create Summary Table (Table 1)
create_demographic_table <- function(data) {
  data %>%
    group_by(income_label) %>%
    summarise(
      n = n(),
      avg_age = mean(age, na.rm = TRUE),
      pct_female = mean(gender == "F") * 100
    ) %>%
    gt() %>%
    tab_header(title = "Patient Demographics by Income Quartile") %>%
    fmt_number(columns = avg_age, decimals = 1) %>%
    fmt_number(columns = pct_female, decimals = 1)
}

# 4. Create Prevalence Plot (Figure 1)
plot_income_prevalence <- function(data) {
  data %>%
    pivot_longer(cols = c(has_anxiety, has_substance_use), 
                 names_to = "condition", values_to = "present") %>%
    group_by(income_label, condition) %>%
    summarise(prevalence = mean(present) * 100, .groups = "drop") %>%
    ggplot(aes(x = income_label, y = prevalence, fill = condition)) +
    geom_col(position = "dodge") +
    theme_minimal() +
    scale_fill_brewer(palette = "Set2", labels = c("Severe Anxiety", "Substance Use")) +
    labs(title = "Condition Prevalence by Income Quartile",
         y = "Prevalence (%)", x = "Income Group")
}

# 5. Create Interaction Plot (Figure 2)
plot_demographic_interaction <- function(data) {
  data %>%
    group_by(income_label, gender, age_group) %>%
    summarise(anxiety_prev = mean(has_anxiety) * 100, .groups = "drop") %>%
    ggplot(aes(x = income_label, y = anxiety_prev, color = gender, group = gender)) +
    geom_line(linewidth = 1) +
    geom_point() +
    facet_wrap(~age_group) +
    theme_minimal() +
    labs(title = "Anxiety Prevalence: Interaction of Income, Gender, and Age",
         y = "Anxiety Prevalence (%)", x = "Income Group")
}