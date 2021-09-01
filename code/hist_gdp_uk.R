library(tidyverse)
library(tidybayes)
library(cmdstanr)
library(bayesplot)
library(shinystan)

## Load historical data

gdps <- read_csv("../data/gdp_estimates.csv")

# Extract annualized growth rates 1856-2016
y_mat <- gdps %>% slice(-1) %>% select(g_igdp, g_egdp, g_ogdp)
y_mat <- y_mat * 100

## Format the data
source("format_data.R")

data <- format_data(y_mat = y_mat)

## compile model

ss_block_diagonal <- cmdstan_model("ss_block_diagonal.stan", include_path = ".")

## Estimate
fit_uk_gdp <- ss_block_diagonal$sample(data = data, parallel_chains = 4)

## Diagnosis of small model

# check gamma, theta, etc. coefficients look similar 
mcmc_hist(fit_uk_gdp$draws(variables = c("gamma", "theta", "sigma_signal", 
                                         "sigma_state", "Omega")))

fit_uk_gdp$summary(variables = c("gamma", "theta", "sigma_signal",
                     "sigma_state", "Omega"))

# extract median estimates
sum_xhat <- fit_uk_gdp$summary(variables = "xhat", 
                               ~quantile(.x, c(.1, .5, .9)))

sum_xhat$date <- gdps %>% slice(-1) %>% .$Date

sum_xhat <- bind_cols(sum_xhat, y_mat)

# Plot estimated state and signals

sum_xhat %>% 
  ggplot(aes(x = date, y = `50%`)) + 
  geom_line(aes(color = "Estimated State")) + 
  geom_line(aes(y = g_igdp, color = "Income")) + 
  geom_line(aes(y = g_egdp, color = "Expenditure")) + 
  geom_line(aes(y = g_ogdp, color = "Output")) + 
  geom_ribbon(aes(ymin = `10%`, ymax = `90%`), alpha=.4, fill = "grey") +
  hrbrthemes::theme_ipsum() + 
  labs(title = "Estimated State and 80% Credible Interval",
       subtitle = "UK GDP growth rate, 1855-2016",
       color = "Legend",
       x = "Time", y = "Posterior Median + 80% CI") +
  scale_color_manual(values = c("Income" = "steelblue", 
                                "Estimated State" = "black",
                                "Expenditure" = "tan",
                                "Output" = "coral")) +
  theme(legend.position = "bottom")

## Model diagnostics
# Check for problems in estimation

fit_uk_gdp$cmdstan_diagnose()
