function [gr,gi] = mcgama(x,y,kf)
% This program is an adaptation (by Yves) from the direct conversion of the 
% corresponding Fortran program in
% S. Zhang & J. Jin "Computation of Special Functions" (Wiley, 1996).
% online: http://iris-lee3.ece.uiuc.edu/~jjin/routines/routines.html
% 
%Converted by f2matlab open source project:
%online: https://sourceforge.net/projects/f2matlab/
% written by Ben Barrowes (barrowes@alum.mit.edu)
%

%     ==========================================================
%     Purpose: This program computes the gamma function (z)
%     or ln[(z)]for a complex argument using
%     subroutine CGAMA
%     Input :  x  --- Real part of z
%     y  --- Imaginary part of z
%     KF --- Function code
%     KF=0 for ln[(z)]
%     KF=1 for (z)
%     Output:  GR --- Real part of ln[(z)]or (z)
%     GI --- Imaginary part of ln[(z)]or (z)
%     Examples:
%     x         y           Re[(z)]Im[(z)]
%     --------------------------------------------------------
%     2.50      5.00     .2267360319D-01    -.1172284404D-01
%     5.00     10.00     .1327696517D-01     .3639011746D-02
%     2.50     -5.00     .2267360319D-01     .1172284404D-01
%     5.00    -10.00     .1327696517D-01    -.3639011746D-02
%     x         y          Re[ln(z)]Im[ln(z)]
%     ---------------------------------------------------------
%     2.50      5.00    -.3668103262D+01     .5806009801D+01
%     5.00     10.00    -.4285507444D+01     .1911707090D+02
%     2.50     -5.00    -.3668103262D+01    -.5806009801D+01
%     5.00    -10.00    -.4285507444D+01    -.1911707090D+02
%     ==========================================================
if nargin<3, kf=1; end % compute gamma(a) by default
if nargin<2, y=zeros(size(x)); end;

gr = zeros(size(x));
gi = zeros(size(x));

if length(x)~=length(y), disp('length of x and y should be equal'), return, end

[x,y,kf,gr,gi]=cgama(x,y,kf,gr,gi);

function [x,y,kf,gr,gi]=cgama(x,y,kf,gr,gi,varargin);
%     =========================================================
%     Purpose: Compute the gamma function (z)or ln[(z)]
%     for a complex argument
%     Input :  x  --- Real part of z
%     y  --- Imaginary part of z
%     KF --- Function code
%     KF=0 for ln[(z)]
%     KF=1 for (z)
%     Output:  GR --- Real part of ln[(z)]or (z)
%     GI --- Imaginary part of ln[(z)]or (z)
%     ========================================================
 a=zeros(1,10);
x1=0.0;
pi=3.141592653589793d0;
a(:)=[8.333333333333333d-02,-2.777777777777778d-03,7.936507936507937d-04,-5.952380952380952d-04,8.417508417508418d-04,-1.917526917526918d-03,6.410256410256410d-03,-2.955065359477124d-02,1.796443723688307d-01,-1.39243221690590d+00];
if(y == 0.0d0&x == fix(x)&x <= 0.0d0);
	gr=1.0d+300;
	gi=0.0d0;
	return;
elseif(x < 0.0d0);
	x1=x;
	y1=y;
	x=-x;
	y=-y;
end;
x0=x;
if(x <= 7.0)
	na=fix(7-x);
	x0=x+na;
end;
z1=sqrt(x0.*x0+y.*y);
th=atan(y./x0);
gr=(x0-.5d0).*log(z1)-th.*y-x0+0.5d0.*log(2.0d0.*pi);
gi=th.*(x0-0.5d0)+y.*log(z1)-y;
for  k=1:10,
	t=z1.^(1-2.*k);
	gr=gr+a(k).*t.*cos((2.0d0.*k-1.0d0).*th);
	gi=gi-a(k).*t.*sin((2.0d0.*k-1.0d0).*th);
end;  
k=10+1;
if(x <= 7.0)
	gr1=0.0d0;
	gi1=0.0d0;
	for  j=0:na-1;
		gr1=gr1+.5d0.*log((x+j).^2+y.*y);
		gi1=gi1+atan(y./(x+j));
	end;  
	j=na-1+1;
	gr=gr-gr1;
	gi=gi-gi1;
end;
if(x1 < 0.0d0);
	z1=sqrt(x.*x+y.*y);
	th1=atan(y./x);
	sr=-sin(pi.*x).*cosh(pi.*y);
	si=-cos(pi.*x).*sinh(pi.*y);
	z2=sqrt(sr.*sr+si.*si);
	th2=atan(si./sr);
	if(sr < 0.0d0);
		th2=pi+th2;
	end;
	gr=log(pi./(z1.*z2))-gr;
	gi=-th1-th2-gi;
	x=x1;
	y=y1;
end;
if(kf == 1);
	g0=exp(gr);
	gr=g0.*cos(gi);
	gi=g0.*sin(gi);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is part of the package EstimHidden devoted to the estimation of 
%
% 1/ the density of X in a convolution model where Z=X+noise1 is observed 
%
% 2/ the functions b (drift) and s^2 (volatility) in an "errors in variables" 
%    model where Z and Y are observed and assumed to follow:
%           Z=X+noise1 and Y=b(X)+s(X)*noise2.
%
% 3/ the functions b (drift) and s^2 (volatility) in an stochastic
%    volatility model where Z is observed and follows:
%           Z=X+noise1 and X_{i+1} = b(X_i) + s(X_i)*noise2
%
% in any cases the density of noise1 is known. We consider three cases for
% this density : Gaussian ('normal'), Laplace ('symexp') and log(Chi2)
% ('logchi2)
%
% See function DeconvEstimate.m and examples in files ExampleDensity.m and
% ExampleRegression.m
%
% Authors : F. COMTE and Y. ROZENHOLC 
%
%
% For more information, see the following references:
%
% DENSITY DECONVOLUTION
%%%%%%%%%%%%%%%%%%%%%%%
%
% 1/ "Penalized contrast estimator for density deconvolution", 
%    The Canadian Journal of Statistics, 34, 431-452, 2006.
%    b y  F .  C O M T E ,  Y .  R O Z E N H O L C ,  and M . - L .  T A U P I N 
%
% 2/ "Finite sample  penalization in adaptive density deconvolution", 
%    Journal of Statistical Computation and Simulation. 
%    Available online.
%    b y  F .  C O M T E ,  Y .  R O Z E N H O L C ,  and M . - L .  T A U P I N 
%
% 3/ "Adaptive density estimation for general ARCH models", 
%    Preprint HAL-CNRS : hal-00101417  at http://hal.archives-ouvertes.fr/
%    b y  F .  C O M T E ,  J. DEDECKER, and  M . - L .  T A U P I N . 
%
% REGRESSION and AUTO-REGRESSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 4/ "Nonparametric estimation of the regression function in an
%    errors-in-variables model", 
%    Statistica Sinica, 17, nĄ3, 1065-1090, 2007. 
%    b y  F .  C O M T E  and M . - L .  T A U P I N 
%
% 5/ "Adaptive estimation of the dynamics of a discrete time stochastic
%    volatility model", 
%    Preprint HAL-CNRS : hal-00170740 at http://hal.archives-ouvertes.fr/
%    by F .  C O M T E, C. LACOUR, and Y. R O Z E N H O L C . 
%
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %
 % Y o u  c a n  u s e  t h i s  s o f t w a r e  f o r  N O N - C O M M E R C I A L  U S E  O N L Y .  
 %
 % Y o u  c a n  d i s t r i b u t e  t h i s  s o f w a r e  u n c h a n g e d  a n d  o n l y  u n c h a n g e d ,  w h i c h  i m p l i e s 
 % i n c l u d i n g  a l l  f i l e s  f o u n d  i n  t h e  f o l d e r  c o i n t a i n n i n g  t h i s  f i l e . 
 %
 % T h i s  s o f t w a r e ,  a n d  a n y  p a r t  o f  i t ,  i s  p r o p o s e d  f o r  N O N - C O M M E R C I A L  U S E  
 % O N L Y .  
 %
 % P l e a s e ,  c o n t a c t  t h e  a u t h o r  f o r  a n d  b e f o r e  a n y  n o n - a c a d e m i c  u s e 
 % o f  t h i s  s o f t w a r e . 
 %
 % T o  r e p r o d u c e  t h i s  c o d e  o r  a n y  p a r t  o f  t h i s  c o d e  i n  t h e  o r i g i n a l  l a n g u a g e  
 % o r  i n  a n y  o t h e r  l a n g u a g e ,  f o r  c o m m e r c i a l  u s e ,  p l e a s e  c o n t a c t  t h e  A u t h o r 
 %
 % F o r  a c a d e m i c  p u r p o s e ,  c i t e  this package and t h e  c o n n e c t e d  p a p e r s . 
 %
 % C o r r e s p o n d i n g  a u t h o r  :  Y .  R o z e n h o l c ,  y v e s . r o z e n h o l c @ u n i v - p a r i s 5 . f r 
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Examples in files ExampleDensity.m and ExampleRegression.m
% 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 


