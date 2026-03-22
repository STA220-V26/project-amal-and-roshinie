library(tidyverse)
library(data.table)

patients <-
readr::read_csv(unz("data.zip", "data-fixed/patients.csv"))

conditions <-
readr::read_csv(unz("data.zip", "data-fixed/conditions.csv"))

