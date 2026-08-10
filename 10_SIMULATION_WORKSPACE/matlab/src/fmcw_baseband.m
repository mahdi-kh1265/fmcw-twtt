function s = fmcw_baseband(t, S)
% FMCW_BASEBAND  Complex-baseband LFM chirp.
%
%   s = fmcw_baseband(t, S)
%
%   s(t) = exp(j * pi * S * t^2)
%
%   True complex-baseband chirp. The RF carrier fc is NOT included.
%
%   Inputs:  t  Column vector of time samples [s]
%            S  Chirp slope [Hz/s]
%   Output:  s  Complex column vector, |s| = 1 for all samples.
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Section A.4

    s = exp(1j * pi * S * t.^2);

end
