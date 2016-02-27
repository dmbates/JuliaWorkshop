library(lme4)
#setwd("~/Desktop/")
rats <- read.table("rats.txt",header=TRUE)
str(rats)
ratslong <- reshape(rats, direction = "long", varying = list(seq_len(ncol(rats))))
str(ratslong, give.attr = FALSE)
xyplot(day)
fm = lmer(day8 ~ 1 + (1|id) + (1|time) ,data=new.rat)



## Prep data for STAN model
library(rstan)
y <- read.table('~/Desktop/rats.txt', header = TRUE)
x <- c(8, 15, 22, 29, 36)
xbar <- mean(x)
N <- nrow(y)
T <- ncol(y)

rats_fit <- stan(file = 'rat_model.stan')