function beat_corrected = correct_cfo(beat, t, Delta_f_hat, direction)
% CORRECT_CFO  Remove estimated CFO from a dechirped beat signal.
%
%   beat_corrected = correct_cfo(beat, t, Delta_f_hat, direction)
%
%   This is the inverse of apply_cfo: it multiplies by the
%   conjugate phase ramp to remove the estimated CFO.
%
%   For direction 'AB': beat_corrected = beat .* exp(-j*2*pi*Delta_f_hat*t)
%   For direction 'BA': beat_corrected = beat .* exp(+j*2*pi*Delta_f_hat*t)
%
%   Invariant:
%     correct_cfo(apply_cfo(beat, t, Df, 'AB'), t, Df, 'AB') == beat
%
%   Inputs:  beat          Complex beat signal [Nx1]
%            t             Time vector [Nx1] [s]
%            Delta_f_hat   Estimated CFO [Hz]
%            direction     String: 'AB' or 'BA'
%
%   Output:  beat_corrected  CFO-corrected beat signal [Nx1]
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section B.4

    if strcmp(direction, 'AB')
        beat_corrected = beat .* exp(-1j * 2*pi * Delta_f_hat * t);
    elseif strcmp(direction, 'BA')
        beat_corrected = beat .* exp(+1j * 2*pi * Delta_f_hat * t);
    else
        error('correct_cfo:badDirection', ...
              'direction must be ''AB'' or ''BA'', got ''%s''', direction);
    end

end
