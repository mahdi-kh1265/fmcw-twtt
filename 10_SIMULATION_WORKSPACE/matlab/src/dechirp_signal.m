function z = dechirp_signal(tx, rx)
% DECHIRP_SIGNAL  Dechirp (mix) local reference and received signal.
%
%   z = dechirp_signal(tx, rx)
%
%   Convention:  z = tx .* conj(rx)
%
%   Local reference chirp times conjugate of received signal.
%   For positive slope S and positive delay delta this yields
%   positive beat frequency: f_b = S * delta.
%
%   Reversing to z = rx .* conj(tx) negates the beat frequency.
%
%   Inputs:  tx  Complex column vector (local/transmitted chirp)
%            rx  Complex column vector (received/delayed chirp)
%   Output:  z   Complex column vector (dechirped beat)
%
%   Invariant: when tx == rx, output is all ones (zero beat).
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections A.6-A.7

    z = tx .* conj(rx);

end
