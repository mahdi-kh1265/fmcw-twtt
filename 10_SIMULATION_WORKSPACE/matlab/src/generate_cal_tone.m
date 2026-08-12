function z_cal = generate_cal_tone(t, Delta_f)
% GENERATE_CAL_TONE  Generate ideal CW calibration tone at frequency Delta_f.
%
%   z_cal = generate_cal_tone(t, Delta_f)
%
%   Models the dechirped output when station A transmits a CW tone and
%   station B mixes it against its own CW LO. The resulting beat is a
%   pure tone at the carrier-frequency offset Delta_f = f_B - f_A.
%
%   Constant phase offsets (f_B*theta + f_A*tau) are omitted because
%   they do not affect the frequency estimate.
%
%   Inputs:  t         Time vector [Nx1] [s]
%            Delta_f   Carrier-frequency offset [Hz]
%   Output:  z_cal     Complex calibration tone [Nx1], |z_cal| = 1
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section B.2

    z_cal = exp(1j * 2*pi * Delta_f * t);

end
