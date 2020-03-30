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
  int N_ob; // number of non-missing
  int N_miss; // number of missing
  int ii_ob[N_ob]; // index of observed
  int ii_miss[N_miss]; // index of missing
  vector[N_ob] Y_ob; //dataset of generated series
}

parameters {
  vector[T] xhat; // state variable
  vector[1] gamma; // state intercept
  vector[1] theta; // AR(1) Coef on state series
  vector[N_miss] Y_miss;
  real<lower = 0> sigma_state; // The scale of innovations to the state
  corr_matrix[P] Omega; // correlation matrix
  vector<lower=0>[P] sigma_signal; // scale of innovations to signal
}
transformed parameters {
  cov_matrix[P] Sigma; // multivariate cov mat for signal
  vector[N_ob + N_miss] Y_vec; // long version of data missing and ob
  matrix[T, P] Y; // the matrix for analysis
  
  Sigma = quad_form_diag(Omega, sigma_signal); // Sigma
  Y_vec[ii_ob] = Y_ob; // Fill y_vec with observed data
  Y_vec[ii_miss] = Y_miss; // Add in parameters in missing slots
  
  for (p in 1:P) { // This loop should fill the columns of Y with Y_miss
    Y[,p] = Y_vec[((p-1)*T + 1):(p*T)];
  }
  
}
model {
  // priors
  xhat[1] ~ normal(3,10); // initial state prior
  sigma_state ~ IG(3, 5); // scale of innovations to state prior
  gamma ~ normal(3, 10); // state intercept prior
  theta ~ normal(0.3, 1); // state autoregressive prior
  
  for (p in 1:P) { // scale of innovations to measurement prior
    sigma_signal[p] ~ IG(3, 5);
  }
  
  Omega ~ lkj_corr(1); // prior for Correlation matrix

  // State Equation
  xhat[2:T] ~ normal(gamma[1]*(1-theta[1]) + xhat[1:(T-1)]*theta[1],sigma_state);

  // Measurement Equations
  for (t in 2:T) {
    Y[t, ] ~ multi_normal(rep_row_vector(xhat[t], P), Sigma);
  }
}





