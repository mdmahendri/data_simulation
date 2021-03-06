library("car")
data("Anscombe")
head(Anscombe)
?Anscombe

mod1_string = " model {
    for (i in 1:length(education)) {
        education[i] ~ dnorm(mu[i], prec)
        mu[i] = b0 + b[1]*income[i] + b[2]*young[i] + b[3]*urban[i]
    }

    b0 ~ dnorm(0.0, 1.0/1.0e6)
    for (i in 1:3) {
        b[i] ~ dnorm(0.0, 1.0/1.0e6)
    }

    prec ~ dgamma(1.0/2.0, 1.0*1500.0/2.0)
    ## Initial guess of variance based on overall
    ## variance of education variable. Uses low prior
    ## effective sample size. Technically, this is not
    ## a true 'prior', but it is not very informative.
    sig2 = 1.0 / prec
    sig = sqrt(sig2)
} "

mod2_string = " model {
    for (i in 1:length(education)) {
        education[i] ~ dnorm(mu[i], prec)
        mu[i] = b0 + b[1]*income[i] + b[2]*young[i] + b[3]*urban[i]
    }

    b0 ~ dnorm(0.0, 1.0/1.0e6)
    for (i in 1:3) {
        b[i] ~ ddexp(0.0, 1.0)
    }

    # use effective sample 1.0 and prior guess 1.0
    prec ~ dgamma(1.0/2.0, 1.0/2.0)
    sig2 = 1.0 / prec
    sig = sqrt(sig2)
} "

params <- c('b0', 'b', 'sig')

# for linear regression
data1_jags = as.list(Anscombe)

# for logistic regression
Xc = scale(Anscombe, center=TRUE, scale=TRUE)
str(Xc)
data2_jags = as.list(data.frame(Xc))

mod1 <- jags.model(textConnection(mod1_string), data = data1_jags, n.chains = 3)
update(mod1, 1e3)
mod1_sim <- coda.samples(mod1, variable.names = params, n.iter = 5e3)
mod1_csim <- as.mcmc(do.call(rbind, mod1_sim))

mod2 <- jags.model(textConnection(mod2_string), data = data2_jags, n.chains = 3)
update(mod2, 1e3)
mod2_sim <- coda.samples(mod2, variable.names = params, n.iter = 5e3)
mod2_csim <- as.mcmc(do.call(rbind, mod2_sim))

# check posterior inferences
summary(mod1_sim)
summary(mod2_sim)

# plot density
par(mfrow=c(3,1))
densplot(mod1_csim[,1:3], xlim = c(-3.0, 3.0))
densplot(mod2_csim[,1:3], xlim = c(-3.0, 3.0))
