function [tau_hat, theta_hat] = solve_twtt(fAB, fBA, S)
% SOLVE_TWTT  Recover propagation delay and clock offset from two-way beats.
%
%   [tau_hat, theta_hat] = solve_twtt(fAB, fBA, S)
%
%   Sign convention (derived in spec Section A.11):
%       T_A(t) = t,   T_B(t) = t + theta   (positive theta => B ahead)
%       delta_AB = tau + theta  =>  f_AB = S*(tau + theta)
%       delta_BA = tau - theta  =>  f_BA = S*(tau - theta)
%
%       tau_hat   = (f_AB + f_BA) / (2*S)
%       theta_hat = (f_AB - f_BA) / (2*S)
%
%   The factors of 2 arise from averaging two one-way measurements,
%   NOT from a monostatic round-trip doubling.
%
%   Inputs:  fAB  Beat frequency from A-to-B link [Hz]
%            fBA  Beat frequency from B-to-A link [Hz]
%            S    Chirp slope [Hz/s]
%   Outputs: tau_hat    Recovered one-way propagation delay [s]
%            theta_hat  Recovered relative clock offset [s]
%
%   No DSP. Pure algebra.
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections A.11 and B.5

    tau_hat   = (fAB + fBA) / (2 * S);
    theta_hat = (fAB - fBA) / (2 * S);

end
