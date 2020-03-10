//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//
// Learn more about model development with Stan at:
//
//    http://mc-stan.org/users/interfaces/rstan.html
//    https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started
//

data {
  int T; // number of obs
  int P; // number of observed variables
  int frequency[P];
  matrix[T,P] Y; //dataset of generated series
}

parameters {
  vector[T] xhat; // state variable
  real<lower = 0> gamma_1; // First factor loading--restricted to positive for identificaton
  vector<lower = 0>[P-1] gamma_rest; // The rest of the factor loadings
  vector[1] theta; // AR(1) Coef on state series
  real<lower = 0> sigma_state; // The scale of innovations to the state
}
transformed parameters {
  vector[P] gamma;
  
  // Need to create a complete factor loading vector
  
  gamma[1] = gamma_1;
  gamma[2:P] = gamma_rest;
  
}

model {
  // priors
  xhat[1] ~ normal(0,1);
  sigma_state ~ normal(0, .3); 
  gamma ~ normal(0, 1);
  theta ~ normal(0, 1);

  // State Equation
  for(t in 2:T) {
    xhat[t] ~ normal(xhat[t-1]*theta[1],sigma_state);
  }

  // Measurement Equations
  for(t in 1:T) {
    for(p in 1:P) {
      if(Y[t,p] != -999) {
        int freq;
        freq = frequency[p] - 1;
        if(freq>1 && t >2) {
          Y[t,p] ~ normal(((freq + 1.0)^-1)*sum(xhat[(t-freq):t])*gamma[p],1);
        }
      } 
    }
  }
}

