

data {
// number of students
  int<lower=0> N;
// number of schools
  int<lower=0> J;
// school ID
  int<lower=1> school[N];
// student score  
  real score[N];
// student Socioeconomic  Score (SES) value  
// real ses[N];
} 



parameters {
// intercept
  real beta_0;
// random school intercept  
  real a[J];
// sd for school effect
  real<lower=0,upper=100> sigma_a;
// sd for individual scores  
  real<lower=0,upper=100> sigma;
} 

transformed parameters {
// declarations
// school means
  real mu_j[J];
// student means
  real mu[N];

// definitions
  for ( j in 1:J )
    mu_j[j] <- beta_0 + a[j];

  for ( i in 1:N )
    mu[i] <- mu_j[school[i]];
}

model {
//  beta_0 ~ normal(0,100)
  a ~ normal (0, sigma_a);
  score ~ normal(mu, sigma);
}

