# This script performs analysis of the thought probe response and generates figure 2c.

# Load necessary libraries
library(tidyverse)
library(ggpubr)
library(effsize)

#set working directory and read data tables
setwd("D:/ankit backup/EEG pilot1/etc/erp_data/second attempt/till 19 sub/analysis trial wise/analysis for LMM")
data_tp_ida <- read.csv("tp_ida_allsub.csv")
data_tp_eda <- read.csv("tp_eda_allsub.csv")


# Add a "Condition" column to each table to distinguish between IDA and EDA
data_tp_ida <- data_tp_ida %>%
  mutate(Condition = "IDA")

data_tp_eda <- data_tp_eda %>%
  mutate(Condition = "EDA")

# Combine the two tables into one long-format dataframe
data_long <- bind_rows(data_tp_ida, data_tp_eda) %>%
  pivot_longer(cols = -c(SubID, Condition), 
               names_to = "Option", 
               values_to = "Percentage")

# Inspect the combined dataframe
head(data_long)

# Convert columns to factors where appropriate
data_long <- data_long %>%
  mutate(Condition = factor(Condition, levels = c("IDA", "EDA")),
         Option = factor(Option, levels = unique(Option)))

# Paired t-tests for each option
test_results <- data_long %>%
  group_by(Option) %>%
  summarise(p_value = t.test(
    Percentage[Condition == "IDA"], 
    Percentage[Condition == "EDA"], 
    paired = TRUE
  )$p.value) %>%
  mutate(Significant = case_when(
    p_value < 0.001 ~ "***",
    p_value < 0.01 ~ "**",
    p_value < 0.05 ~ "*",
    TRUE ~ "ns"
  ))

# Print the test results
print(test_results)

# Add significance information to the main data for plotting
data_long <- data_long %>%
  left_join(test_results, by = "Option")

# Compute mean and standard deviation of differences for each option
cohen_d_results <- data_long %>%
  group_by(Option) %>%
  summarise(
    Mean_Diff = mean(Percentage[Condition == "IDA"] - Percentage[Condition == "EDA"]),
    SD_Diff = sd(Percentage[Condition == "IDA"] - Percentage[Condition == "EDA"]),
    Cohens_d = Mean_Diff / SD_Diff  # Cohen's d formula for paired samples
  )

# Print results
print(cohen_d_results)

# Create the box plot
plot_box <- ggplot(data_long, aes(x = Option, y = Percentage, fill = Condition)) +
  geom_boxplot(width = 0.2, position = position_dodge(0.9), outlier.shape = NA) + # Box plot
  geom_jitter(aes(color = Condition), position = position_jitterdodge(jitter.width = 0.2), size = 1.5, alpha = 0.8) + # Data points
  geom_text(data = test_results, aes(x = Option, y = 100, label = Significant), 
            inherit.aes = FALSE, size = 5, vjust = -0.5) + # Significance stars
  labs(
    x = "Thought-probe Response",
    y = "Percentage Response",
    fill = "Condition") +
  scale_x_discrete(labels = c(
    "Option.1" = "On-task",
    "Option.2" = "Mental elaboration",
    "Option.3" = "Task-related interference",
    "Option.4" = "External distraction",
    "Option.5" = "Inattentiveness",
    "Option.6" = "Mind wandering"
  )) + # Custom x-axis labels
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Set2") +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 14),  # Increase x-axis text size
    axis.text.y = element_text(size = 14),  # Increase y-axis text size
    axis.title.x = element_text(size = 14, face = "bold"),  # Increase x-axis label size
    axis.title.y = element_text(size = 14, face = "bold"),  # Increase y-axis label size
    legend.text = element_text(size = 14),  # Adjust legend text size
    legend.title = element_text(size = 14, face = "bold"),  # Adjust legend title size
    strip.text = element_text(size = 13, face = "bold"),  # Adjust facet labels' font size
  ) +
  ylim(0, 110) # Adjust y-axis for significance stars

# Show the plot
print(plot_box)
