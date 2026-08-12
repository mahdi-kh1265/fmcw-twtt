function z_despread = despread_code(z, code, L, N)
% DESPREAD_CODE  Despread a received/dechirped signal using a code template.
%
%   z_despread = despread_code(z, code, L, N)
%
%   Element-wise multiplication of the dechirped signal by the code
%   template.  For the correct code with aligned chips:
%       c_i * conj(c_i) = |c_i|^2 = 1  (for ±1 codes)
%   The result is the uncoded beat.
%
%   For the wrong code, the product c_j * c_i scrambles the signal
%   and spreads its spectral energy.
%
%   Inputs:  z      Dechirped signal [Nx1]
%            code   Code vector [1xL] of ±1 values
%            L      Code length
%            N      Total samples
%
%   Output:  z_despread  Despreaded signal [Nx1]
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section C.7

    if mod(N, L) ~= 0
        error('despread_code:badLength', ...
              'N = %d must be divisible by L = %d.', N, L);
    end

    N_chip = N / L;

    c = zeros(N, 1);
    for k = 1:L
        idx_start = (k-1)*N_chip + 1;
        idx_end   = k*N_chip;
        c(idx_start:idx_end) = code(k);
    end

    z_despread = z .* c;

end
