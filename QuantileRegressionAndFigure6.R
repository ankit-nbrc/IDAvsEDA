# Load required libraries
library(lqmm)
library(ggplot2)
library(dplyr)

#set working directory and read table 
setwd("D:/ankit backup/EEG pilot1/etc/erp_data/second attempt/till 19 sub/analysis trial wise/analysis for LMM")
data <- read.csv("data_table_alphaF1POz.csv")

data$ConditionID <- as.factor(data$ConditionID)
levels(data$ConditionID)


################################################################################
# Quantile regression model and compile results

# Define tau values
taus <- c(0.2, 0.5, 0.8)

# Fit quantile regression models for each tau
models <- lapply(taus, function(tau) {
  lqmm(
    fixed = AbsoluteError ~ ERP + Beta_encoding + AlphaF1_encoding + AlphaPOz_encoding + RT_I + RT_C + ConditionID + 
      ERP:ConditionID + Beta_encoding:ConditionID + 
      AlphaF1_encoding:ConditionID + AlphaPOz_encoding:ConditionID + RT_I:ConditionID + RT_C:ConditionID,
    random = ~1 | SubjectID,
    group = SubjectID,
    tau = tau,
    data = data,
    control = lqmmControl(LP_max_iter = 4000, LP_tol_ll = 0.001)
  )
})

# Fit the null model (intercept only)
null_model <- lqmm(
  fixed = AbsoluteError ~ 1,
  random = ~1 | SubjectID,
  group = SubjectID,
  tau = 0.2, # Tau value for null model doesn't matter for comparison
  data = data,
  control = lqmmControl(LP_max_iter = 4000, LP_tol_ll = 0.001)
)
summary(null_model)

# Extract model summaries and AICs
results <- lapply(models, summary)
aics <- c(sapply(models, function(model) AIC(model)), AIC(null_model))

# Helper function to calculate significance stars
get_signif_stars <- function(p_value) {
  if (p_value < 0.001) {
    "***"
  } else if (p_value < 0.01) {
    "**"
  } else if (p_value < 0.05) {
    "*"
  } else {
    ""
  }
}

# Combine results into a comparison table
comparison_table_alphaf1poz <- do.call(rbind, lapply(seq_along(results), function(i) {
  coef_table <- results[[i]]$tTable
  data.frame(
    Tau = taus[i],
    Coefficient = rownames(coef_table),
    Estimate = coef_table[, "Value"],
    `Std. Error` = coef_table[, "Std. Error"],
    `P-Value` = coef_table[, "Pr(>|t|)"],
    Significance = sapply(coef_table[, "Pr(>|t|)"], get_signif_stars),
    AIC = aics[i]
  )
}))

comparison_table_alphaf1poz$adjusted_p <- p.adjust(comparison_table_alphaf1poz$P.Value, method = "fdr")  # FDR correction
comparison_table_alphaf1poz$significanceAdjusted <- sapply(comparison_table_alphaf1poz$adjusted_p, get_signif_stars)

#############################################################################################################################
#line plots

quantile_theme <- function(base_size = 18) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text( hjust = 0.5, size = base_size + 4),
      axis.title.x = element_text(size = base_size + 2), # Increase x-axis title font size
      axis.title.y = element_text(size = base_size + 2), # Increase y-axis title font size
      axis.text.x = element_text(size = base_size - 2), # Increase x-axis tick font size
      axis.text.y = element_text(size = base_size - 2), # Increase y-axis tick font size
      legend.title = element_text(size = base_size - 2), # Increase legend title font size
      legend.text = element_text(size = base_size - 4), # Increase legend text font size
      panel.grid.minor = element_blank()
    )
}

# 1. ConditionID Main Effects ---------------------------------------------
condition_data <- comparison_table_alphaf1poz %>%
  filter(grepl("^ConditionID[0-9]+$", Coefficient) & 
           significanceAdjusted != "") %>%
  mutate(Condition = sub("ConditionID", "", Coefficient))

if(nrow(condition_data) > 0) {
  # Create a named vector to map the condition values to legend labels
  condition_labels <- c("2" = "EDA")
  
  condition_plot <- ggplot(condition_data, 
                           aes(x = Tau, y = Estimate, color = Condition)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 3) +
    geom_ribbon(aes(ymin = Estimate - 1.96*Std..Error,
                    ymax = Estimate + 1.96*Std..Error,
                    fill = Condition),
                alpha = 0.2, color = NA) +
    labs(title = "ConditionID Effects Across Quantiles",
         subtitle = "Main Effects",
         x = "Quantile (τ)", 
         y = "Coefficient Estimate") +
    # Add these two scale functions to rename the legend values
    scale_color_manual(values = c("2" = "#F8766D"), labels = condition_labels) +
    scale_fill_manual(values = c("2" = "#F8766D"), labels = condition_labels) +
    quantile_theme(base_size = 18) +
    scale_x_continuous(breaks = taus) +
    theme(legend.position = "top")
  
  # png("ConditionID_Effects.png", width = 7, height = 5, units = "in", res = 600)
  print(condition_plot)
  #dev.off()
}


# 2. Beta_encoding × ConditionID Interaction ------------------------------
# beta_data section
beta_data <- comparison_table_alphaf1poz %>%
  filter(grepl("Beta_encoding:ConditionID", Coefficient)) %>%  # Remove the significance filter here
  mutate(Condition = sub("Beta_encoding:ConditionID", "", Coefficient)) %>%
  filter(Condition == "2") %>% # Ensure Condition is '2'
  filter(significanceAdjusted != "" | Tau == 0.8) # Allow Tau 0.8 regardless of significance

#Ensure 'Tau' is numeric
beta_data$Tau <- as.numeric(as.character(beta_data$Tau))


if (nrow(beta_data) > 0) {
  beta_plot <- ggplot(beta_data,
                      aes(x = Tau, y = Estimate)) +
    geom_line(linewidth = 1.2, color = "#E41A1C") + # Set consistent line color
    geom_point(size = 3, color = "#E41A1C") + # Set consistent point color
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
    geom_ribbon(aes(ymin = Estimate - 1.96 * `Std..Error`,
                    ymax = Estimate + 1.96 * `Std..Error`),
                alpha = 0.2, fill = "#E41A1C") + # Set consistent ribbon color
    labs(title = "Beta Encoding × Condition Interaction Effects",
         x = "Quantile (τ)",
         y = "Interaction Effect Size") +
    theme_minimal(base_size = 18) +
    scale_x_continuous(breaks = taus) +
    theme(legend.position = "none") # Remove legend
  
  #png("betaplot.png", width = 7, height = 5, units = "in", res = 600)
  print(beta_plot)
  #dev.off()
}

# 3. RT_I Effect Plot -----------------------------------------------------
rt_i_plot <- comparison_table_alphaf1poz %>%
  filter(Coefficient == "RT_I") %>%
  ggplot(aes(x = Tau, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = Estimate - 1.96*Std..Error,
                  ymax = Estimate + 1.96*Std..Error),
              fill = "#FF6F61", alpha = 0.2) +
  geom_line(color = "#FF6F61", linewidth = 1.2) +
  geom_point(color = "#FF6F61", size = 4, shape = 19) +
  scale_x_continuous(breaks = taus, limits = range(taus)) +
  labs(title = "Effect of Intermediate Task Reaction Time",
       x = "Quantile Level (τ)",
       y = "Coefficient Estimate\n(Impact on Absolute Error)") +
  quantile_theme()

#png("rt_i_plot.png", width = 7, height = 5, units = "in", res = 600)
print(rt_i_plot)
#dev.off()

# 4. RT_C Effect Plot -----------------------------------------------------
rt_c_plot <- comparison_table_alphaf1poz %>%
  filter(Coefficient == "RT_C") %>%
  ggplot(aes(x = Tau, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = Estimate - 1.96*Std..Error,
                  ymax = Estimate + 1.96*Std..Error),
              fill = "#6B5B95", alpha = 0.2) +
  geom_line(color = "#6B5B95", linewidth = 1.2) +
  geom_point(color = "#6B5B95", size = 4, shape = 19) +
  scale_x_continuous(breaks = taus, limits = range(taus)) +
  labs(title = "Effect of Color-Recall Task Reaction Time",
       x = "Quantile Level (τ)",
       y = "Coefficient Estimate\n(Impact on Absolute Error)") +
  quantile_theme()

png("rt_c_plot.png", width = 7, height = 5, units = "in", res = 600)
print(rt_c_plot)
dev.off()

# Display plots
print(rt_i_plot)
print(rt_c_plot)