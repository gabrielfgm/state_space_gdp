library(tidyverse)
library(tidybayes)
library(cmdstanr)
library(bayesplot)
library(posterior)

## Load historical data

gdpo <- read_csv("../data/estimated_weights_GDP_O.csv")

gdpo <- gdpo %>% 
  mutate(wA = w1 * Agriculture,
         wI = w2 * Industry,
         wS = w3 * Services)

# The weights are extracted from the series as X*w = GDP, w = X^-1 * GDP
# Lets double check that the weight*GDP = Component
gdpo$GDP[1] * gdpo$w1[1] 
gdpo$Agriculture[1] * gdpo$w1[1]

# Make a vector of weights that is missing where not observed
observed_weights <- c(1381, 1522, 1600, 1700)


## compile model

local_level_gen <- cmdstan_model("local_level_components.stan")

## make data
Y <- gdpo %>% select(Agriculture, Industry, Services)
data <- list(Y = Y,
             T = nrow(Y),
             P = ncol(Y),
             weights = gdpo %>% select(w1, w2, w3))

## Estimate
fit_uk_gdp <- local_level_gen$sample(data = data, chains = 2,
                                     parallel_chains = 2, iter_sampling = 4000,
                                     adapt_delta = .9, max_treedepth = 12)

## Diagnosis of small model

# check gamma, theta, etc. coefficients look similar 
mcmc_hist(fit_uk_gdp$draws(variables = c("gamma", "theta", "sigma_signal", 
                                         "sigma_state", "Omega")))

fit_uk_gdp$summary(variables = c("gamma", "theta", "sigma_signal",
                                 "sigma_state", "Omega"))

# extract median estimates
gdp_est <- fit_uk_gdp$summary(variables = "gdp", 
                               ~quantile(.x, c(.1, .5, .9)))

gdp_est <- bind_cols(gdp_est, gdpo)

# Plot estimated state and signals

gdp_est %>% 
  ggplot(aes(x = Year, y = `50%`)) + 
  geom_line(aes(color = "Estimated State")) + 
  geom_line(aes(y = GDP, color = "Broadberry et. al.")) + 
  geom_ribbon(aes(ymin = `10%`, ymax = `90%`), alpha=.4, fill = "grey") +
  hrbrthemes::theme_ipsum() + 
  labs(title = "Estimated State and 80% Credible Interval",
       subtitle = "UK GDP 1270-1700",
       color = "Legend",
       x = "Time", y = "Posterior Median + 80% CI") +
  scale_color_manual(values = c("Estimated State" = "coral", 
                                "Broadberry et. al." = "black")) +
  theme(legend.position = "bottom")

# repeat for agriculture

# extract median estimates
agg_est <- fit_uk_gdp$summary(variables = "xhat", 
                              ~quantile(.x, c(.025, .5, .975)))

agg_est$Year <- rep(gdpo$Year, 3)
agg_est$measured <- c(gdpo$Agriculture, gdpo$Industry, gdpo$Services)
agg_est$component <- rep(c("Agriculture", "Industy", "Services"), each = nrow(gdpo))

agg_est

# Plot estimated state and signals

agg_est %>% 
  ggplot(aes(x = Year, y = `50%`, group = component, color = component)) + 
  geom_line(aes(linetype = "Estimated State")) + 
  #geom_line(aes(y = measured, linetype = "Broadberry et. al.")) + 
  geom_ribbon(aes(ymin = `2.5%`, ymax = `97.5%`), alpha=.4, fill = "grey") +
  hrbrthemes::theme_ipsum() + 
  labs(title = "Estimated State and 95% Credible Interval",
       subtitle = "UK GDP Components 1270-1700",
       color = "Legend",
       x = "Time", y = "Posterior Median + 80% CI") +
  theme(legend.position = "bottom")

## Look at correlation matrix

fit_uk_gdp$summary(variables = "Omega")
fit_uk_gdp$summary(variables = "sigma_signal")

## look at the evolution of the weights

fit_uk_gdp$draws(variables = "w") %>% 
  spread_draws(w[time, component]) %>%
  median_hdi() %>% 
  ggplot(aes(time, w, group = component, color = component)) +
    facet_wrap(~component, nrow = 3) +
    geom_line() + 
    geom_ribbon(aes(ymin = .lower, ymax = .upper), alpha=.4, fill = "grey") 

## Model diagnostics
# Check for problems in estimation

fit_uk_gdp$cmdstan_diagnose()

fit_uk_gdp$summary(variables = "w")
  
  