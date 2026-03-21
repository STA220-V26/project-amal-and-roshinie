# Anxiety, Addiction, and Income: A Health Data Analysis

### Authors
- Amal
- Roshinie

### Course
STA220 — Data Project

> **Note:** This report was generated using synthetic data! It is only used for 
> demonstration purposes and does not reflect real patients or healthcare providers.

---

## Table of Contents
1. Executive Summary
2. Introduction
3. Data Overview
4. Analysis
5. Key Findings & Discussion
6. Limitations

---

## Executive Summary
This project examines the relationship between household income and the prevalence 
of severe anxiety and substance use disorders in a US patient population.

**Research Questions:**
- Is income associated with the prevalence of severe anxiety?
- Is income associated with substance use disorders (alcohol, drugs, opioids)?
- Do anxiety and addiction co-occur more frequently among lower-income patients?
- Does the relationship between income and these conditions differ by gender?

---

## Introduction
Mental health disorders and substance use disorders are major public health challenges. 
Social and economic factors — particularly income — may play a significant role in 
both the development and treatment of these conditions. Income is widely used in 
epidemiological research as a proxy for socioeconomic status, reflecting access to 
resources, living conditions, and overall quality of life. We therefore focus on 
income as our primary socioeconomic indicator to explore its association with 
anxiety and addiction in this patient population.

## Data Overview
This project uses the following datasets from the STA220 course (synthetic US health data):

| Dataset | Description |
|---|---|
| `patients.csv` | Demographic and socioeconomic data including income |
| `conditions.csv` | Patient diagnoses including anxiety and addiction disorders |

---

## Analysis Plan
1. Load and clean patient and condition data
2. Create binary indicators for anxiety and addiction per patient
3. Categorize income into low / medium / high groups
4. Descriptive analysis: prevalence by income group
5. Visualizations: bar charts and tables
6. Interpretation of results

---

## Key Findings & Discussion
*To be completed as analysis progresses.*

---

## Limitations
- This analysis shows associations but cannot establish causal relationships
- Results are based on synthetic data and may not reflect real-world patterns
- Other confounding variables not captured in the dataset may influence 
  results, such as history of trauma, social isolation, or employment 
  status, which may have an equal or greater effect on anxiety and 
  addiction than income alone.
  
---

## Reproducibility
This project uses a `{targets}` pipeline. To reproduce the analysis, run:
```r
targets::tar_make()
```

## Repository Structure
```
R/            # Analysis scripts
_targets.R    # Workflow pipeline  
README.md     # Project description
```
