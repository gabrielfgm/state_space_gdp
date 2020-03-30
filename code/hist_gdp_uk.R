library(tidyverse)
library(tidybayes)
library(rstan)
library(bayesplot)

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

## Load historical data

gdps <- read_csv("../data/gdp_estimates.csv")

# Extract annualized growth rates 1856-2016
y_mat <- gdps %>% slice(-1) %>% select(g_igdp, g_egdp, g_ogdp)
y_mat <- y_mat * 100

# Get time and measure dimensions
T_obs <- nrow(y_mat)
P_obs <- ncol(y_mat)

# collapse to a vector
y_vec <- y_mat %>% 
  gather() %>% .$value

# Index observed values
which_ob <- which(!is.na(y_vec))
which_miss <- which(is.na(y_vec))

# Number of missing and observed
N_ob <- length(which_ob)
N_miss <- length(which_miss)

# Data for estimation
y <- na.omit(y_vec)

## Fitting the model

data <- list(T = T_obs, P = P_obs, 
             N_ob = N_ob, N_miss = N_miss,
             ii_ob = which_ob, ii_miss = which_miss,
             Y_ob = y)

fit_uk_gdp <- stan("ss_block_diagonal.stan", data = data, 
                    chains = 4, iter = 4000)

## Diagnosis of small model

# check gamma, theta, etc. coefficients look similar 
plot(fit_uk_gdp, pars = c("gamma", "theta", "sigma_signal", 
                           "sigma_state", "Sigma"))

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
       color = "Legend",
       x = "Time", y = "Posterior Median + 80% CI") +
  scale_color_manual(values = c("Income" = "coral", 
                                "Estimated State" = "black",
                                "Expenditure" = "tan",
                                "Output" = "steelblue")) +
  theme(legend.position = "bottom")

## Model diagnostics
# Check for problems in estimation

library(shinystan)

uk_gdp_diag <- launch_shinystan(fit_uk_gdp)
