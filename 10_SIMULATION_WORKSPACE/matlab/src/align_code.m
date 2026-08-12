function c_shifted = align_code(code, L, N, Fs, delta)
% ALIGN_CODE  Generate a time-shifted code template for alignment correction.
%
%   c_shifted = align_code(code, L, N, Fs, delta)
%
%   When a coded chirp is delayed by delta, the received code is
%   c(t - delta), which no longer aligns with the local unshifted
%   template c(t).  This function generates the shifted template
%   so that despreading uses the correctly aligned code.
%
%   Implementation: evaluates which chip each sample time (t - delta)
%   falls into, clamping to valid chip indices.
%
%   Inputs:  code   Code vector [1xL] of ±1 values
%            L      Code length
%            N      Total samples
%            Fs     Sample rate [Hz]
%            delta  Estimated delay [s]
%
%   Output:  c_shifted  Shifted code template [Nx1]
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section C.10

    T_chip = (N / Fs) / L;
    t = (0:N-1).' / Fs;
    t_shifted = t - delta;

    c_shifted = zeros(N, 1);
    for n = 1:N
        chip_idx = floor(t_shifted(n) / T_chip) + 1;
        chip_idx = max(1, min(L, chip_idx));  % clamp to valid range
        c_shifted(n) = code(chip_idx);
    end

end
