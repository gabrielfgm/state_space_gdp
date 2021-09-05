# R code to run the stan code in file ss_simple.stan
# Estimates a simple state space model for p
# measurement vectors and 1 state

library(tidyverse)
library(tidybayes)
library(cmdstanr)
library(bayesplot)

## Generate some fake data

# dimensions
n_obs <- 100
n_param <- 2

# True parameters 

initial_state <- .2
true_gamma <- 2
true_theta <- .8

true_sigma_s <- .3
true_sigma_g <- c(.5, .7)

# true unobservables
eps_g_1 <- rnorm(n_obs, 0, true_sigma_g[1])
eps_g_2 <- rnorm(n_obs, 0, true_sigma_g[2])

eps_state <- rnorm(n_obs, 0, true_sigma_s)

true_state <- numeric(n_obs)
true_state[1] <- initial_state

for (i in 2:n_obs) {
  true_state[i] <- true_gamma*(1-true_theta) + true_theta * true_state[i-1] + eps_state[i]
}

# observables

y_mat <- tibble(true_state+eps_g_1, true_state + eps_g_2)

## Fitting the model
source("format_data.R")
data <- format_data(y_mat = y_mat)

## compile model
ss_block_diagonal <- cmdstan_model("ss_block_diagonal.stan", include_paths = ".")

fit_stan <- ss_block_diagonal$sample(data = data, chains = 4, parallel_chains = 4)

## Diagnosis of small model

# check gamma
mcmc_recover_hist(fit_stan$draws(variables = "gamma"), true = true_gamma)

# check theta
mcmc_recover_hist(fit_stan$draws(variables = "theta"), true = true_theta)

# check Sigma
mcmc_hist(fit_stan$draws(variables = "Sigma"))

# check variances
mcmc_recover_hist(fit_stan$draws(variables = "sigma_signal"), true = true_sigma_g)
mcmc_recover_hist(fit_stan$draws(variables = "sigma_state"), true = true_sigma_s)

# extract median estimates
sum_xhat <- fit_stan$summary(variables = "xhat", 
                               ~quantile(.x, c(.1, .5, .9)))

sum_xhat$true_state <- true_state

sum_xhat %>% 
  ggplot(aes(x = 1:n_obs, y = `50%`)) + 
  geom_line(aes(color = "Estimated State")) + 
  geom_line(aes(y = true_state, color = "True State")) + 
  geom_ribbon(aes(ymin = `10%`, ymax = `90%`), alpha=.4, fill = "grey") +
  hrbrthemes::theme_ipsum() + 
  labs(title = "Estimated State and 80% Credible Interval", 
       color = "Legend",
       x = "Time", y = "Posterior Median + 80% CI") +
  scale_color_manual(values = c("True State" = "coral", "Estimated State" = "black")) +
  theme(legend.position = "bottom")

sum_xhat %>% 
  ggplot(aes(true_state, `50%`)) +
  geom_point() +
  hrbrthemes::theme_ipsum() +
  geom_abline(slope = true_theta, intercept = true_gamma*(1-true_theta), 
              color = "coral")+
  labs(title = "Estimated Median and True State Generating Variable",
       x = "True State", y = "Estimated Medians",
       subtitle = "annotated with true regression slope")

## Try simple data estimate

library(readxl)

df <- read_xlsx("../data/gdpplus.xlsx")
df %>% dim()

y_mat <- df %>% filter(OBS_YEAR < 2012) %>% select(GRGDP_DATA, GRGDI_DATA)

## Fitting the model

data <- format_data(y_mat)

fit_stan_gdp <- ss_block_diagonal$sample(data = data, 
                                         parallel_chains = 4, 
                                         iter_sampling = 4000)

## Diagnosis of small model

# check gamma, theta, etc. coefficients look similar 
mcmc_intervals(fit_stan_gdp$draws(variables = c("gamma", "theta", "sigma_signal", 
                                                "sigma_state", "Sigma")))


# check against their point estimates
aruoba <- tibble(mean = c(3.06, .62, 5.17, 
                          3.86, 1.43, 2.7),
                 `25%` = c(2.77, .57, 4.39,
                           3.34, .96, 2.25),
                 `75%` = c(3.34, .68, 5.95,
                           4.48, 1.95, 3.22),
                 Study = "Aruoba et. al.",
                 params = c("mu", "rho", "sigma_gg", 
                            "sigma_ee", "sigma_ei", "sigma_ii"))

param_comp <- fit_stan_gdp$summary(variables = c("gamma", "theta", "sigma_state", "Sigma"),
                     mean, ~quantile(.x, c(.25, .75))) %>% 
  filter(variable != "Sigma[1,2]") %>% 
  mutate(Study = "Mesevage",
         params = c("mu", "rho", "sigma_gg", 
                    "sigma_ee", "sigma_ei", "sigma_ii")) %>% 
  select(-variable) %>% 
  bind_rows(aruoba)

param_comp[param_comp$Study == "Mesevage" & param_comp$params == "sigma_gg", 1:3] <-
  param_comp[param_comp$Study == "Mesevage" & param_comp$params == "sigma_gg", 1:3]^2 %>% 
  round(2)

param_comp

# plot parameter comparisons

param_comp %>% 
  ggplot(aes(Study, mean, ymin = `25%`, ymax = `75%`, color = Study)) + 
  facet_wrap(~params, scales = "free") +
  geom_pointrange() +
  hrbrthemes::theme_ipsum() +
  ggtitle("Comparison of parameter estimates and inter-quartile ranges",
          subtitle = "Stan implementation vs Aruoba et. al.")

ggsave("../figures/param_compare.png", width = 8, height = 5, dpi = 500)

# Plot the estimated state against the true

mcmc_recover_scatter(fit_stan_gdp$draws(variables = "xhat"), 
                     true = df %>% filter(OBS_YEAR < 2012) %>% .$GDPPLUS_DATA)

# extract median estimates
sum_xhat <- fit_stan_gdp$summary(variables = "xhat", 
                               ~quantile(.x, c(.025, .5, .975)))

sum_xhat$true_state <- df %>% filter(OBS_YEAR < 2012) %>% .$GDPPLUS_DATA
sum_xhat <- bind_cols(sum_xhat, y_mat)

sum_xhat %>% 
  ggplot(aes(x = 1:nrow(sum_xhat), y = `50%`)) + 
  geom_line(aes(color = "Estimated State")) + 
  geom_line(aes(y = true_state, color = "GDPPlus Fed")) + 
  geom_ribbon(aes(ymin = `2.5%`, ymax = `97.5%`), alpha=.4, fill = "grey") +
  hrbrthemes::theme_ipsum() + 
  labs(title = "Estimated State and 95% Credible Interval", 
       color = "Legend",
       x = "Time", y = "Posterior Median + 95% CI") +
  scale_color_manual(values = c("GDPPlus Fed" = "coral", 
                                "Estimated State" = "black")) +
  theme(legend.position = "bottom")

ggsave("../figures/gdpplus_compare.png", width = 8, height = 5, dpi = 500)

sum_xhat %>% 
  slice(-1) %>% 
  ggplot(aes(true_state, `50%`)) +
  geom_point() +
  hrbrthemes::theme_ipsum() +
  labs(title = "Estimated Median and True State Generating Variable",
       x = "GDPPlus Fed", y = "Estimated Medians")
