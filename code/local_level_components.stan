//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.

data {
  int T; // number of obs
  int P; // number of observed variables
  matrix[T,P] Y; //dataset of generated series
  matrix[T,P] weights;
}

parameters {
  matrix[T,P] xhat; // state variable
  vector[P] gamma;
  vector[P] theta; // AR(1) Coef on state series
  vector<lower = 0>[P] sigma_state; // The scale of innovations to the state
  vector<lower=0>[P] sigma_signal; //vector of variances for the observations
  corr_matrix[P] Omega; // correlation matrix
  simplex[P] w[T]; // the weights for the components
}

transformed parameters {
  cov_matrix[P] Sigma; // multivariate cov mat for signal
  
  Sigma = quad_form_diag(Omega, sigma_signal); // Sigma
}

model {
  // priors
  xhat[1,] ~ normal(20,10);
  sigma_state ~ normal(1, 5); 
  gamma ~ normal(0, 1);
  theta ~ normal(0, 1);
  sigma_signal ~ normal(1, 5);
  Omega ~ lkj_corr(1); // prior for Correlation matrix

  for (t in 1:T) {
    w[t,] ~ dirichlet(rep_vector(1, P));
  }

  // weight estimation
  for (p in 1:P) {
    weights[,p] ~ normal(w[,p], .1);
  }

  // State Equation
  for(p in 1:P) {
    xhat[2:T,p] ~ normal(gamma[p]*(1-theta[p]) + xhat[1:(T-1),p]*theta[p],sigma_state[p]);
  }

  // Measurement Equations
  for(t in 1:T) {
    Y[t,] ~ multi_normal(xhat[t,], Sigma);
  }
}

generated quantities {
  vector[T] gdp;

  for (t in 1:T) {
    gdp[t] = dot_product(w[t,], xhat[t,]);
  }

}

