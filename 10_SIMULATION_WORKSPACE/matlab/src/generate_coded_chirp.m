function s_coded = generate_coded_chirp(t, S, code, L)
% GENERATE_CODED_CHIRP  Generate a phase-coded FMCW chirp.
%
%   s_coded = generate_coded_chirp(t, S, code, L)
%
%   Multiplies the baseband FMCW chirp by a piecewise-constant binary
%   phase code.  s_coded = s_FMCW .* c, where c[n] = code(chip_index).
%
%   The observation window is divided into L equal chips of N_chip = N/L
%   samples each.  N must be exactly divisible by L.
%
%   Inputs:  t      Time vector [Nx1] [s]
%            S      Chirp slope [Hz/s]
%            code   Code vector [1xL] of ±1 values
%            L      Code length (must divide N = length(t))
%
%   Output:  s_coded  Coded chirp [Nx1], |s_coded| = 1
%
%   Invariant: for code = [+1, +1, ...] (all ones), output = fmcw_baseband(t, S).
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section C.5

    N = length(t);

    if mod(N, L) ~= 0
        error('generate_coded_chirp:badLength', ...
              'N = %d must be divisible by L = %d.', N, L);
    end

    N_chip = N / L;

    % Generate uncoded FMCW chirp
    s_fmcw = fmcw_baseband(t, S);

    % Build piecewise-constant code signal
    c = zeros(N, 1);
    for k = 1:L
        idx_start = (k-1)*N_chip + 1;
        idx_end   = k*N_chip;
        c(idx_start:idx_end) = code(k);
    end

    % Apply code
    s_coded = s_fmcw .* c;

end
