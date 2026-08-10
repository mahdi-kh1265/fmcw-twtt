function result = estimate_beat_phase_slope(beat, Fs)
% ESTIMATE_BEAT_PHASE_SLOPE  Beat frequency via least-squares phase-slope fit.
%
%   result = estimate_beat_phase_slope(beat, Fs)
%
%   This is the authoritative V0/V1 numerical estimator.
%
%   Algorithm:
%       1. phi = unwrap(angle(beat))
%       2. Fit phi[n] = m*n + b  via least squares  (n = 0,1,...,N-1)
%       3. f_est = m * Fs / (2*pi)
%
%   The LS normal equations are solved explicitly (no toolbox).
%
%   Inputs:  beat  Complex beat signal [Nx1]
%            Fs    Sample rate [Hz]
%   Output:  result  Struct with fields:
%              .f_est          Estimated beat frequency [Hz]
%              .phi0           Phase intercept [rad]
%              .residual_rms   RMS of LS phase-fit residual [rad]
%
%   Invariant: for a noise-free complex tone, residual_rms < 1e-10 rad.
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections B.5 and F.3

    N = length(beat);

    % Unwrap phase
    phi = unwrap(angle(beat));

    % Sample indices (column)
    n = (0:N-1).';

    % LS normal equations for phi = m*n + b
    %   [N*Sn2 - Sn^2] * m = N*Snp - Sn*Sp
    %   [N*Sn2 - Sn^2] * b = Sn2*Sp - Sn*Snp
    Sn  = N*(N-1)/2;                    % sum of 0:N-1
    Sn2 = N*(N-1)*(2*N-1)/6;            % sum of (0:N-1).^2
    Sp  = sum(phi);
    Snp = sum(n .* phi);

    denom = N * Sn2 - Sn^2;
    m = (N * Snp - Sn * Sp) / denom;
    b = (Sn2 * Sp - Sn * Snp) / denom;

    % Slope -> frequency
    result.f_est = m * Fs / (2 * pi);

    % Intercept
    result.phi0 = b;

    % Residual RMS
    phi_fit  = m * n + b;
    residual = phi - phi_fit;
    result.residual_rms = sqrt(mean(residual.^2));

end
