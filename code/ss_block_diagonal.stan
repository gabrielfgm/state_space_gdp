//
//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
functions { // to match published paper. stolen from here https://groups.google.com/forum/#!msg/stan-users/sW61HeIT24I/UaLcCHPABQAJ
   // ignoring the 2pi constant
   real IG_log(real x, real mu, real shape){
     return 0.5 * log(shape) - 1.5 * log(x) - shape * square( (x - mu) / mu) / x;
   }
}

data {
  int T; // number of obs
  int P; // number of observed variables
  vector[P] Y[T]; //dataset of generated series
}

parameters {
  vector[T] xhat; // state variable
  vector[1] gamma; // state intercept
  vector[1] theta; // AR(1) Coef on state series
  real<lower = 0> sigma_state; // The scale of innovations to the state
  corr_matrix[P] Omega; // correlation matrix
  vector<lower=0>[P] sigma_signal; // scale of innovations to signal
}
transformed parameters {
  cov_matrix[P] Sigma; // multivariate cov mat for signal
  
  Sigma = quad_form_diag(Omega, sigma_signal);
}
model {
  // priors
  xhat[1] ~ normal(3,10);
  sigma_state ~ IG(10, 15); 
  gamma ~ normal(3, 10);
  theta ~ normal(0.3, 1);
  
  for (p in 1:P) {
    sigma_signal[p] ~ IG(10, 15);
  }
  
  Omega ~ lkj_corr(1);

  // State Equation
  xhat[2:T] ~ normal(gamma[1]*(1-theta[1]) + xhat[1:(T-1)]*theta[1],sigma_state);

  // Measurement Equations
  for (t in 2:T) {
    Y[t, ] ~ multi_normal(rep_row_vector(xhat[t-1], 2), Sigma);
  }
}





