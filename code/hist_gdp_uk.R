library(tidyverse)
library(tidybayes)
library(rstan)
library(bayesplot)
library(shinystan)

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

## Load historical data

gdps <- read_csv("../data/gdp_estimates.csv")

# Extract annualized growth rates 1856-2016
y_mat <- gdps %>% slice(-1) %>% select(g_igdp, g_egdp, g_ogdp)
y_mat <- y_mat * 100

## Format the data
source("format_data.R")

data <- format_data(y_mat = y_mat)

## Estimate
fit_uk_gdp <- stan("ss_block_diagonal.stan", data = data, 
                    chains = 4, iter = 8000)

## Diagnosis of small model

# check gamma, theta, etc. coefficients look similar 
plot(fit_uk_gdp, pars = c("gamma", "theta", "sigma_signal", 
                           "sigma_state", "Omega"))

summary(fit_uk_gdp, pars = c("gamma", "theta", "sigma_signal",
                              "sigma_state", "Omega"), 
        probs = c(0.25, 0.5, 0.75))$summary

# extract median estimates
sum_xhat <- as_tibble(summary(fit_uk_gdp, 
                              pars = "xhat", 
                              probs = c(0.1, 0.5, 0.9))$summary)

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

uk_gdp_diag <- launch_shinystan(fit_uk_gdp)
