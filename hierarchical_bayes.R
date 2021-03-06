setwd('/storage/Code/r/simdat')
dat <- read.csv('pctgrowth.csv')
head(dat)

library(rjags)
mod_string <- "model {
    
    for (i in 1:length(y)) {
        y[i] ~ dnorm(theta[grp[i]], sig2)
    }
    
    for (j in 1:max(grp)) {
        theta[j] ~ dnorm(mu, tau2)
    }
    
    mu ~ dnorm(0, 1.0/1e6)
    tau2 ~ dgamma(1.0/2.0, 1.0*3.0 / 2.0)
    sig2 ~ dgamma(2.0/2.0, 2.0*1.0 / 2.0)
}"

data_jags <- as.list(dat)
params <- c('theta')

mod <- jags.model(textConnection(mod_string), data = data_jags, n.chains = 3)
update(mod, 1e3)
mod_sim <- coda.samples(mod, variable.names = params, n.iter = 5e3)
mod_csim <- as.mcmc(do.call(rbind, mod_sim))

gelman.diag(mod_sim)

#check difference to model that assume no hierarchy
means_anova <- tapply(dat$y, INDEX=dat$grp, FUN=mean)
means_theta <- colMeans(mod_csim)

plot(means_anova)
points(means_theta, col="red")

#question 2
library("MASS")
data("OME")

dat = subset(OME, OME != "N/A")
dat$OME = factor(dat$OME) # relabel OME
dat$ID = as.numeric(factor(dat$ID)) # relabel ID so there are no gaps in numbers (they now go from 1 to 63)

## Original reference model and covariate matrix
mod_glm = glm(Correct/Trials ~ Age + OME + Loud + Noise, data=dat, weights=Trials, family="binomial")
X = model.matrix(mod_glm)[,-1]

## Original model (that needs to be extended)
mod_string = " model {
	for (i in 1:length(y)) {
		y[i] ~ dbin(phi[i], n[i])
		logit(phi[i]) = alpha[ID[i]] + b[1]*Age[i] + b[2]*OMElow[i] + b[3]*Loud[i] + b[4]*Noiseincoherent[i]
	}

    for (j in 1:max(ID)) {
        alpha[j] ~ dnorm(mu, tau2)
    }

	for (k in 1:4) {
		b[k] ~ dnorm(0.0, 1.0/4.0^2)
	}

    mu ~ dnorm(0, 1.0/10^2)
    tau2 ~ dgamma(1.0/2.0, 1.0/2.0)
	
} "

data_jags = as.list(as.data.frame(X))
data_jags$y = dat$Correct
data_jags$n = dat$Trials
data_jags$ID = dat$ID
params <- c('alpha', 'b')

mod <- jags.model(textConnection(mod_string), data = data_jags, n.chains = 3)
update(mod, 1e3)
mod_sim <- coda.samples(mod, variable.names = params, n.iter = 5e3)

gelman.diag(mod_sim)
autocorr.diag(mod_sim)
dic <- dic.samples(mod, n.iter = 1e3)
