library(tidyverse)
library(tidybayes)
library(rstan)
library(bayesplot)

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

## Try simple data estimate

library(readxl)

df <- read_xlsx("../data/gdpplus.xlsx")
df

y_mat <- as.matrix(df[1:nrow(df),5:6])

T_obs <- nrow(y_mat)
P_obs <- ncol(y_mat)

y_vec <- df %>% select(GRGDP_DATA, GRGDI_DATA) %>% 
  gather() %>% select(value) %>% .$value

## Put some extra NA in
set.seed(42)
y_vec[sample(1:length(y_vec), 10, replace = F)] <- NA

which_ob <- which(!is.na(y_vec))
which_miss <- which(is.na(y_vec))

N_ob <- length(which_ob)
N_miss <- length(which_miss)

y <- na.omit(y_vec)

## Fitting the model

data <- list(T = T_obs, P = P_obs, 
             N_ob = N_ob, N_miss = N_miss,
             ii_ob = which_ob, ii_miss = which_miss,
             Y_ob = y)

fit_stan_na <- stan("ss_block_diagonal.stan", data = data, 
                     chains = 4, iter = 4000)

## Diagnosis of small model

# check gamma, theta, etc. coefficients look similar 
plot(fit_stan_na, pars = c("gamma", "theta", "sigma_signal", 
                            "sigma_state", "Sigma"))

summary(fit_stan_na, pars = c("gamma", "theta", 
                               "sigma_state", "Sigma"), 
        probs = c(0.25, 0.5, 0.75))$summary

# Plot the estimated state against the true

# mcmc_intervals(fit_stan, regex_pars = "xhat") + coord_flip()+ 
#   theme(axis.text.x = element_text(angle = 90, hjust = 1))

# extract median estimates
sum_xhat <- as_tibble(summary(fit_stan_na, pars = "xhat", probs = c(0.1, 0.5, 0.9))$summary)

sum_xhat$true_state <- df$GDPPLUS_DATA

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
  hrbrthemes::theme_ipsum() +
  labs(title = "Estimated Median and True State Generating Variable",
       x = "GDPPlus Fed", y = "Estimated Medians")
