library(tidyverse)
library(janitor)
library(gt)
library(broom)

# 1. Clean Patients
clean_patients <- function(path) {
  read_csv(path, show_col_types = FALSE) %>%
    janitor::remove_empty(quiet = FALSE) %>%
    janitor::remove_constant(quiet = FALSE) %>%
    distinct(id, .keep_all = TRUE) %>%
    mutate(
      birthdate = as.Date(birthdate),
      deathdate = as.Date(deathdate),
      age = as.integer(difftime(as.Date("2024-01-01"),
                                birthdate,
                                units = "days") / 365.25),
      age_group = factor(
        ifelse(age < 35, "Under 35", "35 and over"),
        levels = c("Under 35", "35 and over")
      ),
      income_log = log(income)
    ) %>%
    filter(
      age >= 0,
      income >= 1000,
      is.na(deathdate),
      age >= 18
    ) %>%
    select(id, age, age_group, gender, income, income_log)
}

# 2. Flag Conditions using SNOMED codes
identify_conditions <- function(path) {
  anxiety_code <- 80583007
  addiction_codes <- c(6525002, 10939881000119104, 361055000, 5602001, 7200002)
  
  read_csv(path, show_col_types = FALSE) %>%
    group_by(patient) %>%
    summarise(
      has_anxiety = any(code == anxiety_code, na.rm = TRUE),
      has_addiction = any(code %in% addiction_codes, na.rm = TRUE)
    ) %>%
    ungroup()
}

# 3. Summary Table
create_demographic_table <- function(data) {
  data %>%
    group_by(age_group, gender) %>%
    summarise(
      n = n(),
      avg_age = mean(age, na.rm = TRUE),
      avg_income = mean(income, na.rm = TRUE),
      anxiety_pct = round(mean(has_anxiety) * 100, 1),
      addiction_pct = round(mean(has_addiction) * 100, 1),
      .groups = "drop"
    ) %>%
    gt() %>%
    tab_header(title = "Patient Demographics by Age Group and Gender") %>%
    fmt_number(columns = c(avg_age, avg_income), decimals = 1) %>%
    cols_label(
      age_group = "Age Group",
      gender = "Gender",
      n = "N",
      avg_age = "Mean Age",
      avg_income = "Mean Income ($)",
      anxiety_pct = "Anxiety (%)",
      addiction_pct = "Addiction (%)"
    )
}

# 4. Condition Prevalence by Income Group
plot_income_prevalence <- function(data) {
  data %>%
    mutate(income_group = cut(income_log,
                               breaks = 4,
                               labels = c("Lowest", "Lower-Mid",
                                          "Upper-Mid", "Highest"))) %>%
    pivot_longer(cols = c(has_anxiety, has_addiction),
                 names_to = "condition",
                 values_to = "present") %>%
    group_by(income_group, condition) %>%
    summarise(prevalence = mean(present) * 100, .groups = "drop") %>%
    mutate(condition = recode(condition,
                               "has_anxiety" = "Severe Anxiety",
                               "has_addiction" = "Substance Use")) %>%
    ggplot(aes(x = income_group, y = prevalence, fill = condition)) +
    geom_col(position = "dodge") +
    theme_minimal() +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "Condition Prevalence by Income Group",
      y = "Prevalence (%)",
      x = "Income Group (Log-transformed)",
      fill = "Condition"
    )
}

# 5. Anxiety Prevalence by Income, Gender and Age Group
plot_demographic_interaction <- function(data) {
  data %>%
    mutate(income_group = cut(income_log,
                               breaks = 4,
                               labels = c("Lowest", "Lower-Mid",
                                          "Upper-Mid", "Highest"))) %>%
    group_by(income_group, gender, age_group) %>%
    summarise(anxiety_prev = mean(has_anxiety) * 100, .groups = "drop") %>%
    ggplot(aes(x = income_group, y = anxiety_prev,
               color = gender, group = gender)) +
    geom_line(linewidth = 1) +
    geom_point() +
    facet_wrap(~ age_group) +
    theme_minimal() +
    labs(
      title = "Anxiety Prevalence: Interaction of Income, Gender, and Age",
      y = "Anxiety Prevalence (%)",
      x = "Income Group (Log-transformed)",
      color = "Gender"
    )
}

# 6. Logistic Regression Models
run_models <- function(data) {
  data_older <- data %>% filter(age_group == "35 and over")
  
  model_addiction <- glm(has_addiction ~ income_log + gender,
                          data = data_older,
                          family = binomial)
  
  model_anxiety <- glm(has_anxiety ~ gender + age_group,
                        data = data,
                        family = binomial)
  
  list(
    addiction_35plus = broom::tidy(model_addiction, exponentiate = TRUE,
                                    conf.int = TRUE),
    anxiety_all = broom::tidy(model_anxiety, exponentiate = TRUE,
                               conf.int = TRUE)
  )
}