## Helper script for formatting the data

format_data <- function(y_mat) {
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
  
  ## Return the data object
  data
}