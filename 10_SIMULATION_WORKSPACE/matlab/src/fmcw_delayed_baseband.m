function r = fmcw_delayed_baseband(t, S, delta)
% FMCW_DELAYED_BASEBAND  Analytically delayed complex-baseband chirp.
%
%   r = fmcw_delayed_baseband(t, S, delta)
%
%   r(t) = exp(j * pi * S * (t - delta)^2)
%
%   Delay is applied by evaluating the analytic phase at (t - delta).
%   Sub-sample delays (e.g. 10 ps at 10 MHz sampling) remain exact.
%
%   PROHIBITED: circshift, round(delta*Fs), floor, sinc interpolation,
%   or any operation with delay granularity 1/Fs.
%
%   Inputs:  t      Column vector of time samples [s]
%            S      Chirp slope [Hz/s]
%            delta  One-way delay [s]
%   Output:  r      Complex column vector, |r| = 1 for all samples.
%
%   Invariant: fmcw_delayed_baseband(t,S,0) == fmcw_baseband(t,S)
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Section A.5

    r = exp(1j * pi * S * (t - delta).^2);

end
