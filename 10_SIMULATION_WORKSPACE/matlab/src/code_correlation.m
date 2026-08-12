function R = code_correlation(z, code, L, N)
% CODE_CORRELATION  Compute normalized code correlation for node ID.
%
%   R = code_correlation(z, code, L, N)
%
%   Despreads the dechirped signal with the code template and computes
%   the normalized magnitude of the sum.  For a pure tone despreaded
%   with the correct aligned code, R approaches 1.  For the wrong code,
%   R approaches 0.
%
%   Inputs:  z      Dechirped signal [Nx1]
%            code   Code vector [1xL] of ±1 values
%            L      Code length
%            N      Total samples
%
%   Output:  R      Normalized scalar correlation (0 to 1)
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section C.9

    z_despread = despread_code(z, code, L, N);
    R = abs(sum(z_despread)) / N;

end
