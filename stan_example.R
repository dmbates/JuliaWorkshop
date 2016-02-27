
# Fitting the MathAchieve mixed model using lmer
library(lme4)
library(nlme)
data(MathAcheivement)
data(MathAchieve)
students <- MathAchieve
fit.lmer = lmer(MathAch ~ 1 + (1 | School), students)


# prepping the stan data 
sub = with(MathAchieve, levels(School)[1:8])
students = MathAchieve[MathAchieve$School %in% sub,]
students$School = factor(as.character(students$School))
schools = MathAchSchool[MathAchSchool$School %in% sub,]
schools$School = factor(as.character(schools$School))
##
## First Example
##

math_data.1 = list(N = nrow(students),
                   J = nrow(schools),
                   score = students$MathAch,
                   ses = students$SES,
                   school = as.integer(students$School))

setwd("~/Desktop/")
fit.stan <- fit <- stan(file = 'schools.stan', data = math_data.1, 
                        iter = 1000, chains = 4)
