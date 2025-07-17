# Install packages if needed
install.packages("dplyr")
install.packages("tidyr")
install.packages("purrr")

library(dplyr)
library(tidyr)
library(purrr)


# Working dir and data tables
setwd("dirpath")
data_tp_ida <- read.csv("tp_ida_allsub.csv")
data_tp_eda <- read.csv("tp_eda_allsub.csv")


# Reshape IDA data
tp_ida_long <- data_tp_ida %>%
  pivot_longer(cols = -SubID, names_to = "Option", values_to = "Percentage")

# Reshape EDA data
tp_eda_long <- data_tp_eda %>%
  pivot_longer(cols = -SubID, names_to = "Option", values_to = "Percentage")

# Merge datasets
data_long <- merge(tp_ida_long, tp_eda_long, by = c("SubID", "Option"))

# Split data by Option
data_split <- group_split(data_long, Option)

# Function to compute Wilcoxon W, p, z, and Cohen's d
compute_stats <- function(df) {
  option_name <- unique(df$Option)
  diffs <- df$Percentage.x - df$Percentage.y
  
  # Remove zero differences 
  nonzero_diffs <- diffs[diffs != 0]
  n <- length(nonzero_diffs)
  
  # Wilcoxon test
  w_test <- wilcox.test(nonzero_diffs, paired = FALSE, exact = FALSE)
  W <- as.numeric(w_test$statistic)
  
  # z calculation
  mean_w <- n * (n + 1) / 4
  sd_w <- sqrt(n * (n + 1) * (2 * n + 1) / 24)
  z <- (W - mean_w) / sd_w
  
  # Cohen's d
  mean_diff <- mean(diffs)
  sd_diff <- sd(diffs)
  cohen_d <- mean_diff / sd_diff
  
  tibble(
    Option = option_name,
    W = W,
    wilcox_p = w_test$p.value,
    z = z,
    Mean_Diff = mean_diff,
    SD_Diff = sd_diff,
    Cohens_d = cohen_d
  )
}

# Apply the function to each option
results_list <- map(data_split, compute_stats)

# Combine results
results_combined <- bind_rows(results_list)


