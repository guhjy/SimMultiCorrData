#' @title Generate Variables for Error Loop
#'
#' @description This function simulates the continuous, ordinal (r >= 2 categories), Poisson, or Negative Binomial variables
#'     used in \code{\link[SimMultiCorrData]{error_loop}}.  It is called in each iteration and works pairwise (i.e. for 2 variables).
#'     This function would not ordinarily be called directly by the user.
#'
#' @param marginal a list of length equal \code{k_cat}; the i-th element is a vector of the cumulative
#'     probabilities defining the marginal distribution of the i-th variable;
#'     if the variable can take r values, the vector will contain r - 1 probabilities (the r-th is assumed to be 1)
#' @param support a list of length equal \code{k_cat}; the i-th element is a vector of containing the r
#'     ordered support values; if not provided, the default is for the i-th element to be the vector 1, ..., r
#' @param method the method used to generate the continuous variables.  "Fleishman" uses a third-order polynomial transformation
#'     and "Polynomial" uses Headrick's fifth-order transformation.
#' @param means a vector of means for the continuous variables
#' @param vars a vector of variances
#' @param constants a matrix with \code{k_cont} rows, each a vector of constants c0, c1, c2, c3 (if \code{method} = "Fleishman") or
#'     c0, c1, c2, c3, c4, c5 (if \code{method} = "Polynomial"), like that returned by
#'     \code{\link[SimMultiCorrData]{find_constants}}
#' @param lam a vector of lambda (> 0) constants for the Poisson variables (see \code{\link[stats]{dpois}})
#' @param size a vector of size parameters for the Negative Binomial variables (see \code{\link[stats]{dnbinom}})
#' @param prob a vector of success probability parameters
#' @param mu a vector of mean parameters (*Note: either \code{prob} or \code{mu} should be supplied for all Negative Binomial variables,
#'     not a mixture)
#' @param Sigma the 2 x 2 intermediate correlation matrix generated by \code{\link[SimMultiCorrData]{error_loop}}
#' @param rho_calc the 2 x 2 final correlation matrix calculated in \code{\link[SimMultiCorrData]{error_loop}}
#' @param q the row index of the 1st variable
#' @param r the column index of the 2nd variable
#' @param k_cat the number of ordinal (r >= 2 categories) variables
#' @param k_cont the number of continuous variables
#' @param k_pois the number of Poisson variables
#' @param k_nb the number of Negative Binomial variables
#' @param Y_cat the ordinal variables generated from \code{\link[SimMultiCorrData]{error_loop}}
#' @param Y the continuous (mean 0, variance 1) variables
#' @param Yb the continuous variables with desired mean and variance
#' @param Y_pois the Poisson variables
#' @param Y_nb the Negative Binomial variables
#' @param n the sample size
#' @param seed the seed value for random number generation
#' @import stats
#' @import utils
#' @export
#' @keywords error, correlation
#' @seealso \code{\link[GenOrd]{ordcont}}, \code{\link[SimMultiCorrData]{rcorrvar}}, \code{\link[SimMultiCorrData]{rcorrvar2}},
#'     \code{\link[SimMultiCorrData]{error_loop}}
#'
#' @return A list with the following components:
#' @return \code{Sigma} the intermediate MVN correlation matrix
#' @return \code{rho_calc} the calculated final correlation matrix generated from Sigma
#' @return \code{Y_cat} the ordinal variables
#' @return \code{Y} the continuous (mean 0, variance 1) variables
#' @return \code{Yb} the continuous variables with desired mean and variance
#' @return \code{Y_pois} the Poisson variables
#' @return \code{Y_nb} the Negative Binomial variables
#' @references Please see references for \code{\link[SimMultiCorrData]{error_loop}}.
#'
error_vars <- function(marginal, support, method, means, vars, constants, lam,
                       size, prob, mu, Sigma, rho_calc, q, r, k_cat, k_cont,
                       k_pois, k_nb, Y_cat, Y, Yb, Y_pois, Y_nb, n, seed) {
  eig <- eigen(matrix(c(1, Sigma[q, r], Sigma[r, q], 1), nrow = 2, ncol = 2,
                     byrow = T), symmetric = TRUE)
  sqrteigval <- diag(sqrt(eig$values), nrow = 2, ncol = 2)
  eigvec <- eig$vectors
  fry <- eigvec %*% sqrteigval
  set.seed(seed)
  X <- matrix(rnorm(2*n), n)
  X <- scale(X, TRUE, FALSE)
  X <- X %*% svd(X, nu = 0)$v
  X <- scale(X, FALSE, TRUE)
  X <- fry %*% t(X)
  X <- t(X)
  if (q >= 1 & q <= k_cat & r >= 1 & r <= k_cat) {
    X_cat <- X
    Y_cat[, q] <- as.integer(cut(X_cat[, 1],
                                 breaks = c(min(X_cat[, 1]) - 1,
                                            qnorm(marginal[[q]]),
                                            max(X_cat[, 1]) + 1)))
    Y_cat[, q] <- support[[q]][Y_cat[, q]]
    Y_cat[, r] <- as.integer(cut(X_cat[, 2],
                                 breaks = c(min(X_cat[, 2]) - 1,
                                            qnorm(marginal[[r]]),
                                            max(X_cat[, 2]) + 1)))
    Y_cat[, r] <- support[[r]][Y_cat[, r]]
    rho_calc[q, r] <- cor(Y_cat[, c(q, r)])[1, 2]
  }
  if (q >= 1 & q <= k_cat & r >= (k_cat + 1) & r <= (k_cat + k_cont)) {
    X_cat <- matrix(X[, 1], nrow = n, ncol = 1)
    Y_cat[, q] <- as.integer(cut(X_cat[, 1],
                                 breaks = c(min(X_cat[, 1]) - 1,
                                            qnorm(marginal[[q]]),
                                            max(X_cat[, 1]) + 1)))
    Y_cat[, q] <- support[[q]][Y_cat[, q]]
    X_cont <- matrix(X[, 2], nrow = n, ncol = 1)
    if (method == "Fleishman") {
      Y[, (r - k_cat)] <- constants[(r - k_cat), 1] +
        constants[(r - k_cat), 2] * X_cont[, 1] +
        constants[(r - k_cat), 3] * X_cont[, 1]^2 +
        constants[(r - k_cat), 4] * X_cont[, 1]^3
    }
    if (method == "Polynomial") {
      Y[, (r - k_cat)] <- constants[(r - k_cat), 1] +
        constants[(r - k_cat), 2] * X_cont[, 1] +
        constants[(r - k_cat), 3] * X_cont[, 1]^2 +
        constants[(r - k_cat), 4] * X_cont[, 1]^3 +
        constants[(r - k_cat), 5] * X_cont[, 1]^4 +
        constants[(r - k_cat), 6] * X_cont[, 1]^5
    }
    Yb[, (r - k_cat)] <- means[(r - k_cat)] +
      sqrt(vars[(r - k_cat)]) * Y[, (r - k_cat)]
    rho_calc[q, r] <- cor(cbind(Y_cat[, q], Yb[, (r - k_cat)]))[1, 2]
  }
  if (q >= 1 & q <= k_cat & r >= (k_cat + k_cont + 1) &
      r <= (k_cat + k_cont + k_pois)) {
    X_cat <- matrix(X[, 1], nrow = n, ncol = 1)
    X_pois <- matrix(X[, 2], nrow = n, ncol = 1)
    Y_cat[, q] <- as.integer(cut(X_cat[, 1],
                                 breaks = c(min(X_cat[, 1]) - 1,
                                            qnorm(marginal[[q]]),
                                            max(X_cat[, 1]) + 1)))
    Y_cat[, q] <- support[[q]][Y_cat[, q]]
    Y_pois[, r - (k_cat + k_cont)] <- qpois(pnorm(X_pois[, 1]),
                                            lam[r - (k_cat + k_cont)])
    rho_calc[q, r] <- cor(cbind(Y_cat[, q],
                                Y_pois[, (r - (k_cat + k_cont))]))[1, 2]
  }
  if (q >= 1 & q <= k_cat & r >= (k_cat + k_cont + k_pois + 1) &
      r <= (k_cat + k_cont + k_pois + k_nb)) {
    X_cat <- matrix(X[, 1], nrow = n, ncol = 1)
    X_nb <- matrix(X[, 2], nrow = n, ncol = 1)
    Y_cat[, q] <- as.integer(cut(X_cat[, 1],
                                 breaks = c(min(X_cat[, 1]) - 1,
                                            qnorm(marginal[[q]]),
                                            max(X_cat[, 1]) + 1)))
    Y_cat[, q] <- support[[q]][Y_cat[, q]]
    if (length(prob) > 0) {
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[r - (k_cat + k_cont + k_pois)],
                prob[r - (k_cat + k_cont + k_pois)])
    }
    if (length(mu) > 0) {
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[r - (k_cat + k_cont + k_pois)],
                mu = mu[r - (k_cat + k_cont + k_pois)])
    }
    rho_calc[q, r] <-
      cor(cbind(Y_cat[, q], Y_nb[, (r - (k_cat + k_cont + k_pois))]))[1, 2]
  }
  if (q >= (k_cat + 1) & q <= (k_cat + k_cont) & r >= (k_cat + 1) &
      r <= (k_cat + k_cont)) {
    X_cont <- X
    if (method == "Fleishman") {
      Y[, (q - k_cat)] <- constants[(q - k_cat), 1] +
        constants[(q - k_cat), 2] * X_cont[, 1] +
        constants[(q - k_cat), 3] * X_cont[, 1]^2 +
        constants[(q - k_cat), 4] * X_cont[, 1]^3
      Y[, (r - k_cat)] <- constants[(r - k_cat), 1] +
        constants[(r - k_cat), 2] * X_cont[, 2] +
        constants[(r - k_cat), 3] * X_cont[, 2]^2 +
        constants[(r - k_cat), 4] * X_cont[, 2]^3
    }
    if (method == "Polynomial") {
      Y[, (q - k_cat)] <- constants[(q - k_cat), 1] +
        constants[(q - k_cat), 2] * X_cont[, 1] +
        constants[(q - k_cat), 3] * X_cont[, 1]^2 +
        constants[(q - k_cat), 4] * X_cont[, 1]^3 +
        constants[(q - k_cat), 5] * X_cont[, 1]^4 +
        constants[(q - k_cat), 6] * X_cont[, 1]^5
      Y[, (r - k_cat)] <- constants[(r - k_cat), 1] +
        constants[(r - k_cat), 2] * X_cont[, 2] +
        constants[(r - k_cat), 3] * X_cont[, 2]^2 +
        constants[(r - k_cat), 4] * X_cont[, 2]^3 +
        constants[(r - k_cat), 5] * X_cont[, 2]^4 +
        constants[(r - k_cat), 6] * X_cont[, 2]^5
    }
    Yb[, (q - k_cat)] <- means[(q - k_cat)] +
      sqrt(vars[(q - k_cat)]) * Y[, (q - k_cat)]
    Yb[, (r - k_cat)] <- means[(r - k_cat)] +
      sqrt(vars[(r - k_cat)]) * Y[, (r - k_cat)]
    rho_calc[q, r] <- cor(Yb[, c((q - k_cat), (r - k_cat))])[1, 2]
  }
  if (q >= (k_cat + 1) & q <= (k_cat + k_cont) & r >= (k_cat + k_cont + 1) &
      r <= (k_cat + k_cont + k_pois)) {
    X_cont <- matrix(X[, 1], nrow = n, ncol = 1)
    X_pois <- matrix(X[, 2], nrow = n, ncol = 1)
    if (method == "Fleishman") {
      Y[, (q - k_cat)] <- constants[(q - k_cat), 1] +
        constants[(q - k_cat), 2] * X_cont[, 1] +
        constants[(q - k_cat), 3] * X_cont[, 1]^2 +
        constants[(q - k_cat), 4] * X_cont[, 1]^3
    }
    if (method == "Polynomial") {
      Y[, (q - k_cat)] <- constants[(q - k_cat), 1] +
        constants[(q - k_cat), 2] * X_cont[, 1] +
        constants[(q - k_cat), 3] * X_cont[, 1]^2 +
        constants[(q - k_cat), 4] * X_cont[, 1]^3 +
        constants[(q - k_cat), 5] * X_cont[, 1]^4 +
        constants[(q - k_cat), 6] * X_cont[, 1]^5
    }
    Yb[, (q - k_cat)] <- means[(q - k_cat)] +
      sqrt(vars[(q - k_cat)]) * Y[, (q - k_cat)]
    Y_pois[, r - (k_cat + k_cont)] <- qpois(pnorm(X_pois[, 1]),
                                            lam[r - (k_cat + k_cont)])
    rho_calc[q, r] <- cor(cbind(Yb[, (q - k_cat)],
                                Y_pois[, (r - (k_cat + k_cont))]))[1, 2]
  }
  if (q >= (k_cat + 1) & q <= (k_cat + k_cont) &
      r >= (k_cat + k_cont + k_pois + 1) &
      r <= (k_cat + k_cont + k_pois + k_nb)) {
    X_cont <- matrix(X[, 1], nrow = n, ncol = 1)
    X_nb <- matrix(X[, 2], nrow = n, ncol = 1)
    if (method == "Fleishman") {
      Y[, (q - k_cat)] <- constants[(q - k_cat), 1] +
        constants[(q - k_cat), 2] * X_cont[, 1] +
        constants[(q - k_cat), 3] * X_cont[, 1]^2 +
        constants[(q - k_cat), 4] * X_cont[, 1]^3
    }
    if (method == "Polynomial") {
      Y[, (q - k_cat)] <- constants[(q - k_cat), 1] +
        constants[(q - k_cat), 2] * X_cont[, 1] +
        constants[(q - k_cat), 3] * X_cont[, 1]^2 +
        constants[(q - k_cat), 4] * X_cont[, 1]^3 +
        constants[(q - k_cat), 5] * X_cont[, 1]^4 +
        constants[(q - k_cat), 6] * X_cont[, 1]^5
    }
    Yb[, (q - k_cat)] <- means[(q - k_cat)] +
      sqrt(vars[(q - k_cat)]) * Y[, (q - k_cat)]
    if (length(prob) > 0) {
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[r - (k_cat + k_cont + k_pois)],
                prob[r - (k_cat + k_cont + k_pois)])
    }
    if (length(mu) > 0) {
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[r - (k_cat + k_cont + k_pois)],
                mu = mu[r - (k_cat + k_cont + k_pois)])
    }
    rho_calc[q, r] <- cor(cbind(Yb[, (q - k_cat)],
                                Y_nb[, (r - (k_cat + k_cont + k_pois))]))[1, 2]
  }
  if (q >= (k_cat + k_cont + 1) & q <= (k_cat + k_cont + k_pois) &
      r >= (k_cat + k_cont + 1) & r <= (k_cat + k_cont + k_pois)) {
    X_pois <- X
    Y_pois[, q-(k_cat + k_cont)] <- qpois(pnorm(X_pois[, 1]),
                                          lam[q - (k_cat + k_cont)])
    Y_pois[, r - (k_cat + k_cont)] <- qpois(pnorm(X_pois[, 2]),
                                            lam[r - (k_cat + k_cont)])
    rho_calc[q, r] <- cor(cbind(Y_pois[, (q - (k_cat + k_cont))],
                                Y_pois[, (r - (k_cat + k_cont))]))[1, 2]
  }
  if (q >= (k_cat + k_cont + 1) & q <= (k_cat + k_cont + k_pois) &
      r >= (k_cat + k_cont + k_pois + 1) &
      r <= (k_cat + k_cont + k_pois + k_nb)) {
    X_pois <- matrix(X[, 1], nrow = n, ncol = 1)
    X_nb <- matrix(X[, 2], nrow = n, ncol = 1)
    Y_pois[, q-(k_cat + k_cont)] <- qpois(pnorm(X_pois[, 1]),
                                          lam[q - (k_cat + k_cont)])
    if (length(prob) > 0) {
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[r - (k_cat + k_cont + k_pois)],
                prob[r - (k_cat + k_cont + k_pois)])
    }
    if (length(mu) > 0) {
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[r - (k_cat + k_cont + k_pois)],
                mu = mu[r - (k_cat + k_cont + k_pois)])
    }
    rho_calc[q, r] <- cor(cbind(Y_pois[, (q - (k_cat + k_cont))],
                                Y_nb[, (r - (k_cat + k_cont + k_pois))]))[1, 2]
  }
  if (q >= (k_cat + k_cont + k_pois + 1) &
      q <= (k_cat + k_cont + k_pois + k_nb) &
      r >= (k_cat + k_cont + k_pois + 1) &
      r <= (k_cat + k_cont + k_pois + k_nb)) {
    X_nb <- X
    if (length(prob) > 0) {
      Y_nb[, q - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[q - (k_cat + k_cont + k_pois)],
                prob[q - (k_cat + k_cont + k_pois)])
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 2]), size[r - (k_cat + k_cont + k_pois)],
                prob[r - (k_cat + k_cont + k_pois)])
    }
    if (length(mu) > 0) {
      Y_nb[, q - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 1]), size[q - (k_cat + k_cont + k_pois)],
                mu = mu[q - (k_cat + k_cont + k_pois)])
      Y_nb[, r - (k_cat + k_cont + k_pois)] <-
        qnbinom(pnorm(X_nb[, 2]), size[r - (k_cat + k_cont + k_pois)],
                mu = mu[r - (k_cat + k_cont + k_pois)])
    }
    rho_calc[q, r] <- cor(cbind(Y_nb[, (q - (k_cat + k_cont + k_pois))],
                                Y_nb[, (r - (k_cat + k_cont + k_pois))]))[1, 2]
  }
  rho_calc[r, q] <- rho_calc[q, r]
  return(list(Sigma = Sigma, rho_calc = rho_calc, Y_cat = Y_cat, Y = Y,
              Yb = Yb, Y_pois = Y_pois, Y_nb = Y_nb))
}
