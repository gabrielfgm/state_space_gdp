# R code to run the stan code in file ss_simple.stan
# Estimates a simple state space model for p
# measurement vectors and 1 state

library(tidyverse)
library(tidybayes)
library(rstan)
library(bayesplot)

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

## Generate some fake data

# dimensions
n_obs <- 1000
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

y_mat <- cbind(true_state+eps_g_1, true_state + eps_g_2)

## Fitting the model

data <- list(T = n_obs, P = n_param, Y = y_mat)

fit_stan <- stan("ss_block_diagonal.stan", data = data, 
                 chains = 4, iter = 4000)

## Diagnosis of small model

# check gamma
plot(fit_stan, pars = "gamma") + geom_vline(xintercept = true_gamma)

# check theta
plot(fit_stan, pars = "theta") + geom_vline(xintercept = true_theta)

# check variances
plot(fit_stan, pars = "sigma_signal") + geom_vline(xintercept = true_sigma_g)
plot(fit_stan, pars = "sigma_state") + geom_vline(xintercept = true_sigma_s)

# Plot the estimated state against the true

# mcmc_intervals(fit_stan, regex_pars = "xhat") + coord_flip()+ 
#   theme(axis.text.x = element_text(angle = 90, hjust = 1))

# extract median estimates
sum_xhat <- as_tibble(summary(fit_stan, pars = "xhat", probs = c(0.1, 0.5, 0.9))$summary)

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
  hrbrthemes::theme_ipsum_rc() +
  geom_abline(slope = true_theta, intercept = true_gamma*(1-true_theta), 
              color = "coral")+
  labs(title = "Estimated Median and True State Generating Variable",
       x = "True State", y = "Estimated Medians",
       subtitle = "annotated with true regression slope")

## Try simple data estimate

library(readxl)

df <- read_xlsx("../data/gdpplus.xlsx")
df

y_mat <- as.matrix(df[1:239,5:6])

n_obs <- nrow(y_mat)
n_param <- ncol(y_mat)

## Fitting the model

data <- list(T = n_obs, P = n_param, Y = y_mat)

fit_stan_gdp <- stan("ss_simple.stan", data = data, 
                     chains = 4, iter = 4000)

## Diagnosis of small model

# check gamma
plot(fit_stan_gdp, pars = c("gamma", "theta", "sigma_signal", "sigma_state"))

summary(fit_stan_gdp, pars = c("gamma", "theta", "sigma_signal", "sigma_state"), 
        probs = c(0.1, 0.5, 0.9))$summary

# Plot the estimated state against the true

# mcmc_intervals(fit_stan, regex_pars = "xhat") + coord_flip()+ 
#   theme(axis.text.x = element_text(angle = 90, hjust = 1))

# extract median estimates
sum_xhat <- as_tibble(summary(fit_stan_gdp, pars = "xhat", probs = c(0.1, 0.5, 0.9))$summary)

sum_xhat$true_state <- df$GDPPLUS_DATA[1:239]

sum_xhat %>% 
  ggplot(aes(x = 1:n_obs, y = `50%`)) + 
  geom_line(aes(color = "Estimated State")) + 
  geom_line(aes(y = true_state, color = "GDPPlus Fed")) + 
  geom_ribbon(aes(ymin = `10%`, ymax = `90%`), alpha=.4, fill = "grey") +
  hrbrthemes::theme_ipsum() + 
  labs(title = "Estimated State and 80% Credible Interval", 
       color = "Legend",
       x = "Time", y = "Posterior Median + 80% CI") +
  scale_color_manual(values = c("GDPPlus Fed" = "coral", "Estimated State" = "black")) +
  theme(legend.position = "bottom")

sum_xhat %>% 
  ggplot(aes(true_state, `50%`)) +
  geom_point() +
  hrbrthemes::theme_ipsum_rc() +
  labs(title = "Estimated Median and True State Generating Variable",
       x = "GDPPlus Fed", y = "Estimated Medians")
