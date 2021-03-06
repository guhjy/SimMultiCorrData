% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/denom_corr_cat.R
\name{denom_corr_cat}
\alias{denom_corr_cat}
\title{Calculate Denominator Used in Intercorrelations Involving Ordinal Variables}
\usage{
denom_corr_cat(marginal, support)
}
\arguments{
\item{marginal}{a vector of cumulative probabilities defining the marginal distribution of the variable;
if the variable can take r values, the vector will contain r - 1 probabilities (the r-th is assumed to be 1)}

\item{support}{a vector of containing the ordered support values}
}
\value{
A scalar
}
\description{
This function calculates part of the the denominator used to find intercorrelations involving ordinal variables
    or variables that are treated as ordinal (i.e. count variables in the method used in
    \code{\link[SimMultiCorrData]{rcorrvar2}}).  It uses the formula given by Olsson et al. (1982, \doi{10.1007/BF02294164}) in
    describing polyserial and point-polyserial correlations.  For an ordinal variable with r >= 2 categories, the value is given by:
    \deqn{\sum_{j = 1}^{r-1} \phi(\tau_{j})*(y_{j+1} - y_{j}),} where
    \deqn{\phi(\tau) = (2\pi)^{-1/2} * exp(-0.5 * \tau^2).}  Here, \eqn{y_{j}} is the j-th support
    value and \eqn{\tau_{j}} is \eqn{\Phi^{-1}(\sum_{i=1}^{j} Pr(Y = y_{i}))}.  This function would not ordinarily be called directly by the user.
}
\references{
Olsson U, Drasgow F, & Dorans NJ (1982). The Polyserial Correlation Coefficient. Psychometrika, 47(3): 337-47.
    \doi{10.1007/BF02294164}.
}
\seealso{
\code{\link[SimMultiCorrData]{ordnorm}}, \code{\link[SimMultiCorrData]{rcorrvar}},
    \code{\link[SimMultiCorrData]{rcorrvar2}}, \code{\link[SimMultiCorrData]{findintercorr_cont_cat}},
    \code{\link[SimMultiCorrData]{findintercorr_cont_pois2}}, \cr
    \code{\link[SimMultiCorrData]{findintercorr_cont_nb2}}
}
\keyword{intercorrelation,}
\keyword{ordinal}
