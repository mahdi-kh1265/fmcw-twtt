function [Delta_f_hat, delta_hat] = solve_twtt_updown(f_up, f_down, S)
% SOLVE_TWTT_UPDOWN  Recover CFO and effective directional delay from up/down chirp pair.
%
%   [Delta_f_hat, delta_hat] = solve_twtt_updown(f_up, f_down, S)
%
%   Given a SINGLE-DIRECTION observation (e.g. A->B) with up-chirp (+S)
%   and down-chirp (-S), the beat frequencies are:
%
%       f_up   = +S*delta + Delta_f
%       f_down = -S*delta + Delta_f
%
%   Sum/difference recovery (Roehr 2007 lineage):
%       Delta_f = (f_up + f_down) / 2
%       delta   = (f_up - f_down) / (2*S)
%
%   delta_hat is the EFFECTIVE DIRECTIONAL DELAY for the observed link:
%       For A->B: delta_hat = tau + theta
%       For B->A: delta_hat = tau - theta
%
%   To recover tau and theta independently, apply this solver to BOTH
%   directions and combine:
%       tau_hat   = (delta_AB + delta_BA) / 2
%       theta_hat = (delta_AB - delta_BA) / 2
%
%   Inputs:  f_up    Beat frequency from up-chirp (+S) [Hz]
%            f_down  Beat frequency from down-chirp (-S) [Hz]
%            S       Chirp slope magnitude [Hz/s]  (positive)
%
%   Outputs: Delta_f_hat  Recovered carrier-frequency offset [Hz]
%            delta_hat    Recovered effective directional delay [s]
%
%   No DSP. Pure algebra.
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section A.8

    Delta_f_hat = (f_up + f_down) / 2;
    delta_hat   = (f_up - f_down) / (2 * S);

end
