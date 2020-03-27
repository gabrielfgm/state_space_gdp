Using Bayesian State Space Models to Reconcile Historical GDP Estimates
=======================================================================

The object of this exercise is to try to reconcile historical GDP
estimates by optimally combining them using state space models.

Given a series of measures of GDP such as
![GDP\_i](https://latex.codecogs.com/png.latex?GDP_i "GDP_i"),
![GDP\_e](https://latex.codecogs.com/png.latex?GDP_e "GDP_e"), and
![GDP\_o](https://latex.codecogs.com/png.latex?GDP_o "GDP_o"), for the
income, expenditure, and output approaches to measuring GDP, we might
like to optimally combine them to get a series
![GDP\_c](https://latex.codecogs.com/png.latex?GDP_c "GDP_c") that
reflects the measurement efforts of multiple scholars. Many attempts to
combine GDP measurements exist, and here we follow the approach of
Aruoba et. al. as they designed the state-space estimator for GDPPlus as
implemented by the Philadelphia Federal Reserve.

We stack our GDP measures into a vector
![Y\_t](https://latex.codecogs.com/png.latex?Y_t "Y_t") measured over
time periods ![t](https://latex.codecogs.com/png.latex?t "t") to
![T](https://latex.codecogs.com/png.latex?T "T"). We assume that our
measurements of GDP are generated by true GDP, but are corrupted by
noise:

![Y\_t = \[1, 1, 1\]\' x\_t +
\\epsilon\_t.](https://latex.codecogs.com/png.latex?Y_t%20%3D%20%5B1%2C%201%2C%201%5D%27%20x_t%20%2B%20%5Cepsilon_t. "Y_t = [1, 1, 1]' x_t + \epsilon_t.")

True GDP itself is latent but moves autoregressively:

![x\_t = \\mu (1 - \\rho) + \\rho x\_{t-1} +
\\eta\_t.](https://latex.codecogs.com/png.latex?x_t%20%3D%20%5Cmu%20%281%20-%20%5Crho%29%20%2B%20%5Crho%20x_%7Bt-1%7D%20%2B%20%5Ceta_t. "x_t = \mu (1 - \rho) + \rho x_{t-1} + \eta_t.")

An important consideration is the covariance structure of our
measurements of GDP. It is reasonable to think that they are likely to
be correlated, thus we model the covariance of our system as
block-diagonal in the signals, so that the 4
![\\times](https://latex.codecogs.com/png.latex?%5Ctimes "\times") 4
matrix
![\\Sigma](https://latex.codecogs.com/png.latex?%5CSigma "\Sigma") has
zeros in rows 2:4 of column 1, and in columns 2:4 of row 1.

\
![ \\Sigma = \\begin{bmatrix} \\sigma\_{gg} & 0 & 0 & 0 \\\\ 0 &
\\sigma\_{ii} & \\sigma\_{ie} & \\sigma\_{io} \\\\ 0 & \\sigma\_{ei} &
\\sigma\_{ee} & \\sigma\_{eo} \\\\ 0 & \\sigma\_{oi} & \\sigma\_{oe} &
\\sigma\_{oo} \\end{bmatrix}
](https://latex.codecogs.com/png.latex?%0A%5CSigma%20%3D%20%0A%5Cbegin%7Bbmatrix%7D%0A%5Csigma_%7Bgg%7D%20%26%200%20%26%200%20%26%200%20%5C%5C%0A0%20%26%20%5Csigma_%7Bii%7D%20%26%20%5Csigma_%7Bie%7D%20%26%20%5Csigma_%7Bio%7D%20%5C%5C%0A0%20%26%20%5Csigma_%7Bei%7D%20%26%20%5Csigma_%7Bee%7D%20%26%20%5Csigma_%7Beo%7D%20%5C%5C%0A0%20%26%20%5Csigma_%7Boi%7D%20%26%20%5Csigma_%7Boe%7D%20%26%20%5Csigma_%7Boo%7D%0A%5Cend%7Bbmatrix%7D%0A "
\Sigma = 
\begin{bmatrix}
\sigma_{gg} & 0 & 0 & 0 \\
0 & \sigma_{ii} & \sigma_{ie} & \sigma_{io} \\
0 & \sigma_{ei} & \sigma_{ee} & \sigma_{eo} \\
0 & \sigma_{oi} & \sigma_{oe} & \sigma_{oo}
\end{bmatrix}
")\

We are unfortunately constrained initially to a block-diagonal
formulation so that the system remains identifiable. Aruoba et.
al. suggest two approaches to relaxing this assumption which I will try
to incorporate later.
