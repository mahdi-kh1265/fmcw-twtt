function result = estimate_beat_fft(beat, Fs)
% ESTIMATE_BEAT_FFT  Beat frequency via FFT peak detection (diagnostic).
%
%   result = estimate_beat_fft(beat, Fs)
%
%   This is a DIAGNOSTIC estimator for visualization and coarse sanity
%   checking. It is NOT the authoritative precision estimator.
%
%   Zero-padding changes the displayed frequency grid but does not
%   increase physical observation time or create new information.
%
%   Inputs:  beat  Complex beat signal [Nx1]
%            Fs    Sample rate [Hz]
%   Output:  result  Struct with fields:
%              .f_peak        Frequency of FFT magnitude peak [Hz]
%              .spectrum_mag  Magnitude spectrum [Nx1]
%              .freq_axis     Frequency axis [Hz, Nx1]
%              .df            FFT bin spacing Fs/N [Hz]
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Section B.5

    N = length(beat);

    % FFT bin spacing
    result.df = Fs / N;

    % Compute FFT
    Z = fft(beat);
    result.spectrum_mag = abs(Z);

    % Frequency axis: 0, df, 2*df, ..., (N-1)*df
    result.freq_axis = (0:N-1).' * result.df;

    % Peak in positive-frequency half (bins 1..N/2+1, i.e. indices 1..N_half+1)
    N_half = floor(N/2);
    [~, idx] = max(result.spectrum_mag(1:N_half+1));
    result.f_peak = (idx - 1) * result.df;

end
