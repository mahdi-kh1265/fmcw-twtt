function Delta_f_hat = estimate_cfo_from_tone(z_cal, Fs)
% ESTIMATE_CFO_FROM_TONE  Estimate carrier-frequency offset from a CW tone.
%
%   Delta_f_hat = estimate_cfo_from_tone(z_cal, Fs)
%
%   Delegates to the same phase-slope estimator used by V0/V1.
%   The calibration tone is a pure complex exponential at frequency
%   Delta_f; the LS phase-slope estimator recovers Delta_f exactly
%   in the noise-free ideal model.
%
%   Inputs:  z_cal         Complex calibration tone [Nx1]
%            Fs            Sample rate [Hz]
%   Output:  Delta_f_hat   Estimated carrier-frequency offset [Hz]
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section B.3

    result = estimate_beat_phase_slope(z_cal, Fs);
    Delta_f_hat = result.f_est;

end
