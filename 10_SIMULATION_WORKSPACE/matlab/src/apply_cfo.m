function beat_cfo = apply_cfo(beat, t, Delta_f, direction)
% APPLY_CFO  Apply carrier-frequency offset to a dechirped beat signal.
%
%   beat_cfo = apply_cfo(beat, t, Delta_f, direction)
%
%   For the project's z = LO * conj(RX) mixer convention:
%       A->B link:  CFO adds +Delta_f to beat frequency
%       B->A link:  CFO adds -Delta_f to beat frequency
%
%   where Delta_f = f_B - f_A  (positive means B carrier is higher).
%
%   Implementation: multiplies beat by exp(j * sign * 2*pi*Delta_f*t)
%   where sign = +1 for 'AB' and -1 for 'BA'.
%
%   Inputs:  beat      Complex beat signal [Nx1]
%            t         Time vector [Nx1] [s]
%            Delta_f   Carrier-frequency offset [Hz]  (= f_B - f_A)
%            direction String: 'AB' or 'BA'
%
%   Output:  beat_cfo  CFO-shifted beat signal [Nx1]
%
%   Invariant: apply_cfo(beat, t, 0, 'AB') == beat  (unchanged).
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section A.10

    if strcmp(direction, 'AB')
        beat_cfo = beat .* exp(+1j * 2*pi * Delta_f * t);
    elseif strcmp(direction, 'BA')
        beat_cfo = beat .* exp(-1j * 2*pi * Delta_f * t);
    else
        error('apply_cfo:badDirection', ...
              'direction must be ''AB'' or ''BA'', got ''%s''', direction);
    end

end
