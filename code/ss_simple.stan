//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.

data {
  int T; // number of obs
  int P; // number of observed variables
  matrix[T,P] Y; //dataset of generated series
}

parameters {
  vector[T] xhat; // state variable
  vector[1] gamma;
  vector[1] theta; // AR(1) Coef on state series
  real<lower = 0> sigma_state; // The scale of innovations to the state
  vector<lower=0>[P] sigma_signal; //vector of variances for the observations
}

model {
  // priors
  xhat[1] ~ normal(0,1);
  sigma_state ~ normal(1, 5); 
  gamma ~ normal(0, 1);
  theta ~ normal(0, 1);
  sigma_signal ~ normal(1, 5);

  // State Equation
  for(t in 2:T) {
    xhat[t] ~ normal(gamma[1]*(1-theta[1]) + xhat[t-1]*theta[1],sigma_state);
  }

  // Measurement Equations
  for(t in 1:T) {
    for(p in 1:P) {
          Y[t,p] ~ normal(xhat[t],sigma_signal[P]);
    }
  }
}

