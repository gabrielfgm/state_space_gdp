/* This is just a helper function that defines
the log probability density for the inverse gaussian
distribution 
I am using IG to match the GDPPlus paper. 
Formula tolen from here https://groups.google.com/forum/#!msg/stan-users/sW61HeIT24I/UaLcCHPABQAJ
ignoring the 2pi constant*/

functions {
   real IG_log(real x, real mu, real shape){
     return 0.5 * log(shape) - 1.5 * log(x) - shape * square( (x - mu) / mu) / x;
   }
}
