function cfg = make_default_params()
% MAKE_DEFAULT_PARAMS  Default configuration for V0/V1 FMCW simulation.
%
%   cfg = make_default_params()
%
%   The V0/V1 signal chain requires only cfg.S, cfg.Fs, and cfg.N.
%   Other fields are metadata for documentation and future use.
%
%   All values in SI units (Hz, Hz/s, s, m/s).
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections A.9 and B.5

    % --- Core V0/V1 parameters ---
    cfg.S  = 2.9982e13;    % Chirp slope [Hz/s]  (= 29.982 MHz/us)
    cfg.Fs = 10e6;         % Sample rate [Hz]
    cfg.N  = 256;          % Number of ADC samples

    % --- Metadata (not used in V0/V1 waveform generation) ---
    cfg.fc = 77e9;         % Nominal RF carrier frequency [Hz]
    cfg.c  = 299792458;    % Speed of light [m/s] (exact)

end
