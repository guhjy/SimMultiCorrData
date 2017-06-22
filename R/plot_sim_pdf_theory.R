#' @title Plot Simulated Probability Density Function and Target PDF by Distribution Name or Function
#'
#' @description This plots the pdf of simulated data and overlays the target pdf (if \code{overlay} = TRUE),
#'     which is specified by distribution name (plus up to 3 parameters) or pdf function (plus support bounds).  The simulated data is
#'     scaled and then transformed (i.e. \eqn{sim_y <- sigma * scale(sim_y) + mu}) so that it has the same mean and variance as the
#'     target distribution.  It returns a \code{\link[ggplot2]{ggplot2}} object so the user can modify as necessary.  The graph parameters (i.e. \code{title},
#'     \code{power_color}, \code{target_color}, \code{target_lty}) are \code{\link[ggplot2]{ggplot2}} parameters.  It works for valid or invalid power method pdfs.
#' @param sim_y a vector of simulated data
#' @param title the title for the graph (default = "Simulated Probability Density Function")
#' @param ylower the lower y value to use in the plot (default = NULL, uses minimum simulated y value)
#' @param yupper the upper y value (default = NULL, uses maximum simulated y value)
#' @param power_color the histogram color for the simulated variable
#' @param overlay if TRUE (default), the target distribution is also plotted given either a distribution name (and parameters)
#'     or pdf function fx (with bounds = ylower, yupper)
#' @param target_color the line color for the target pdf
#' @param target_lty the line type for the target pdf (default = 2, dashed line)
#' @param Dist name of the distribution. The possible values are: "Beta", "Chisq", "Exponential", "F", "Gamma", "Gaussian",
#'     "Laplace", "Logistic", "Lognormal", "Pareto", "Rayleigh", "t", "Triangular", "Uniform", "Weibull".
#'     Please refer to the documentation for each package (i.e. \code{\link[stats]{dgamma}})
#'     for information on appropriate parameter inputs.  The pareto (see \code{\link[VGAM]{dpareto}}), generalized
#'     rayleigh (see \code{\link[VGAM]{dgenray}}), and laplace (see \code{\link[VGAM]{dlaplace}}) distributions
#'     come from the \code{\link[VGAM]{VGAM}} package.  The triangular (see \code{\link[triangle]{dtriangle}}) distribution
#'     comes from the \code{\link[triangle]{triangle}} package.
#' @param params a vector of parameters (up to 3) for the desired distribution (keep NULL if \code{fx} supplied instead)
#' @param fx a pdf input as a function of x only, i.e. fx <- function(x) 0.5*(x-1)^2; must return a scalar
#'     (keep NULL if \code{Dist} supplied instead)
#' @import ggplot2
#' @importFrom VGAM dpareto rpareto dgenray rgenray dlaplace rlaplace
#' @importFrom triangle dtriangle rtriangle
#' @export
#' @keywords plot, simulated, theoretical, pdf, Fleishman, Headrick
#' @seealso \code{\link[SimMultiCorrData]{calc_theory}},
#'     \code{\link[ggplot2]{ggplot}}, \code{\link[ggplot2]{geom_line}}, \code{\link[ggplot2]{geom_density}}
#' @return A \code{\link[ggplot2]{ggplot2}} object.
#' @references Headrick TC (2002). Fast Fifth-order Polynomial Transforms for Generating Univariate and Multivariate
#' Non-normal Distributions. Computational Statistics & Data Analysis 40(4):685-711
#' (\href{http://www.sciencedirect.com/science/article/pii/S0167947302000725}{ScienceDirect})
#'
#' Fleishman AI (1978). A Method for Simulating Non-normal Distributions. Psychometrika, 43, 521-532.
#'
#' Headrick TC, Kowalchuk RK (2007). The Power Method Transformation: Its Probability Density Function, Distribution
#'     Function, and Its Further Use for Fitting Data. Journal of Statistical Computation and Simulation, 77, 229-249.
#'
#' Headrick TC, Sheng Y, & Hodis FA (2007). Numerical Computing and Graphics for the Power Method Transformation Using
#'     Mathematica. Journal of Statistical Software, 19(3), 1 - 17. \doi{10.18637/jss.v019.i03}.
#'
#' Headrick TC, Sawilowsky SS (1999). Simulating Correlated Non-normal Distributions: Extending the Fleishman Power
#'     Method. Psychometrika, 64, 25-35.
#'
#' Headrick TC (2004). On Polynomial Transformations for Simulating Multivariate Nonnormal Distributions.
#'     Journal of Modern Applied Statistical Methods, 3, 65-71.
#'
#' Wickham H. ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York, 2009.
#'
#' @examples \dontrun{
#' # Logistic Distribution
#'
#' seed = 1234
#'
#' # Find standardized cumulants
#' stcum <- calc_theory(Dist = "Logistic", params = c(0, 1))
#'
#' # Simulate without the sixth cumulant correction
#' # (invalid power method pdf)
#' Logvar1 <- nonnormvar1(method = "Polynomial", means = 0, vars = 1,
#'                       skews = stcum[3], skurts = stcum[4],
#'                       fifths = stcum[5], sixths = stcum[6],
#'                       Six = NULL, n = 10000, seed = seed)
#'
#' # Plot pdfs of simulated variable (invalid) and theoretical distribution
#' plot_sim_pdf_theory(sim_y = Logvar1$continuous_variable,
#'              title = "Invalid Logistic Simulated PDF", overlay = TRUE,
#'              Dist = "Logistic", params = c(0, 1))
#'
#' # Simulate with the sixth cumulant correction
#' # (valid power method pdf)
#' Logvar2 <- nonnormvar1(method = "Polynomial", means = 0, vars = 1,
#'                       skews = stcum[3], skurts = stcum[4],
#'                       fifths = stcum[5], sixths = stcum[6],
#'                       Six = seq(1.5, 2, 0.05), n = 10000, seed = 1234)
#'
#' # Plot pdfs of simulated variable (invalid) and theoretical distribution
#' plot_sim_pdf_theory(sim_y = Logvar2$continuous_variable,
#'              title = "Valid Logistic Simulated PDF", overlay = TRUE,
#'              Dist = "Logistic", params = c(0, 1))
#' }
#'
plot_sim_pdf_theory <- function(sim_y,
                       title = "Simulated Probability Density Function",
                                ylower = NULL, yupper = NULL,
                                power_color = "dark blue", overlay = TRUE,
                                target_color = "dark green", target_lty = 2,
                                Dist = c("Beta", "Chisq", "Exponential", "F",
                                         "Gamma", "Gaussian", "Laplace",
                                         "Logistic", "Lognormal", "Pareto",
                                         "Rayleigh", "t", "Triangular",
                                         "Uniform", "Weibull"),
                                params = NULL, fx = NULL) {
  theory <- calc_theory(Dist = Dist, params = params)
  mu <- theory[1]
  sigma <- theory[2]
  sim_y <- sigma * scale(sim_y) + mu
  if (is.null(ylower) & is.null(yupper)) {
    ylower <- min(sim_y)
    yupper <- max(sim_y)
  }
  data <- data.frame(x = 1:length(sim_y), y = sim_y,
                     type = as.factor(rep("sim", length(sim_y))))
  plot1 <- ggplot() + theme_bw() + ggtitle(title) +
    geom_density(data = data, aes_(x = ~y, colour = "Density", lty = ~type)) +
    scale_x_continuous(name = "y", limits = c(ylower, yupper)) +
    scale_y_continuous(name = "Probability") +
    theme(plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
          axis.text.x = element_text(size = 10),
          axis.title.x = element_text(size = 13),
          axis.text.y = element_text(size = 10),
          axis.title.y = element_text(size = 13),
          legend.text = element_text(size = 10),
          legend.position = c(0.975, 0.9), legend.justification = c(1, 1)) +
    scale_linetype_manual(name = "", values = 1,
                          labels = "Simulated Variable") +
    scale_colour_manual(name = "", values = c(power_color),
                        labels = "Simulated Variable")
  if (overlay == FALSE) return(plot1)
  if (overlay == TRUE) {
    x <- sim_y
    y_fx <- numeric(length(x))
    if (!is.null(fx)) {
      for (j in 1:length(x)) {
        y_fx[j] <- fx(x[j])
      }
    }
    if (is.null(fx)) {
      D <- data.frame(Dist = c("Beta", "Chisq", "Exponential", "F", "Gamma",
                               "Gaussian", "Laplace", "Logistic", "Lognormal",
                               "Pareto", "Rayleigh", "t", "Triangular",
                               "Uniform", "Weibull"),
                      pdf = c("dbeta", "dchisq", "dexp", "df", "dgamma",
                              "dnorm", "dlaplace", "dlogis", "dlnorm",
                              "dpareto", "dgenray", "dt", "dtriangle",
                              "dunif", "dweibull"),
                      fx = c("rbeta", "rchisq", "rexp", "rf", "rgamma",
                             "rnorm", "rlaplace", "rlogis", "rlnorm",
                             "rpareto", "rgenray", "rt", "rtriangle",
                             "runif", "rweibull"),
                      Lower = as.numeric(c(0, 0, 0, 0, 0, -Inf, -Inf, -Inf,
                                           0, params[1], 0, -Inf, params[1],
                                           params[1], 0)),
                      Upper = as.numeric(c(1, Inf, Inf, Inf, Inf, Inf, Inf,
                                           Inf, Inf, Inf, Inf, Inf, params[2],
                                           params[2], Inf)))
      i <- match(Dist, D$Dist)
      p <- as.character(D$pdf[i])
      for (j in 1:length(x)) {
        if (length(params) == 1) y_fx[j] <- get(p)(x[j], params[1])
        if (length(params) == 2) y_fx[j] <- get(p)(x[j], params[1], params[2])
        if (length(params) == 3) y_fx[j] <- get(p)(x[j], params[1], params[2],
                                                   params[3])
      }
    }
    data2 <- data.frame(x = x, y = y_fx,
                        type = as.factor(rep("theory", length(y_fx))))
    data2 <- data.frame(rbind(data, data2))
    plot1 <- ggplot() + theme_bw() + ggtitle(title) +
      geom_density(data = data2[data2$type == "sim", ],
                   aes_(x = ~y, colour = ~type, lty = ~type)) +
      geom_line(data = data2[data2$type == "theory", ],
                aes_(x = ~x, y = ~y, colour = ~type, lty = ~type)) +
      scale_x_continuous(name = "y", limits = c(ylower, yupper)) +
      scale_y_continuous(name = "Probability") +
      theme(plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
            axis.text.x = element_text(size = 10),
            axis.title.x = element_text(size = 13),
            axis.text.y = element_text(size = 10),
            axis.title.y = element_text(size = 13),
            legend.text = element_text(size = 10),
            legend.position = c(0.975, 0.9), legend.justification = c(1, 1)) +
      scale_linetype_manual(name = "", values = c(1, target_lty),
                            labels = c("Simulated Variable", "Target")) +
      scale_colour_manual(name = "", values = c(power_color, target_color),
                          labels = c("Simulated Variable", "Target"))
    return(plot1)
  }
}