function y=fit_T1_SatRec(xdat,BETA)
%     y= BETA(2) * ( 1 - exp(-xdat/BETA(1)));
    y= BETA(3) + BETA(2) * ( 1 - exp(-xdat/BETA(1)));
return

