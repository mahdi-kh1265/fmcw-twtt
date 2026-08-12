function z_cal = generate_cal_tone_phased(t, Delta_f, tau, theta, f_A)
% GENERATE_CAL_TONE_PHASED  Phase-derived calibration tone observation.
%
%   z_cal = generate_cal_tone_phased(t, Delta_f, tau, theta, f_A)
%
%   Models the dechirped output when station A transmits a CW tone at its
%   carrier frequency f_A, and station B mixes it against its own CW LO
%   at f_B = f_A + Delta_f, using the project convention z = LO * conj(RX).
%
%   Station phase model (CW, no chirp):
%
%       A transmits:       s_A(t)    = exp(j * 2*pi * f_A * t)
%       After delay tau:   r_A(t)    = exp(j * 2*pi * f_A * (t - tau))
%       B's LO (B's clock): lo_B(t) = exp(j * 2*pi * f_B * (t + theta))
%
%   Dechirp (LO * conj(RX)):
%       z_cal(t) = lo_B(t) * conj(r_A(t))
%                = exp(j * 2*pi * [f_B*(t+theta) - f_A*(t-tau)])
%                = exp(j * 2*pi * [Delta_f*t + f_B*theta + f_A*tau])
%
%   The result is a pure tone at frequency Delta_f, plus constant phase
%   phi0 = 2*pi*(f_B*theta + f_A*tau).
%
%   Under the static-tone assumption:
%       - Propagation delay tau contributes ONLY constant phase (f_A*tau).
%       - Clock epoch theta contributes ONLY constant phase (f_B*theta).
%       - The phase slope (d/dt) is exactly Delta_f.
%       - The phase-slope estimator therefore recovers Delta_f.
%
%   Inputs:
%       t         Time vector [Nx1] [s]
%       Delta_f   Carrier-frequency offset [Hz]  (= f_B - f_A)
%       tau       One-way propagation delay [s]
%       theta     Relative clock epoch offset [s]
%       f_A       Station A carrier frequency [Hz]  (e.g. 77e9)
%
%   Output:
%       z_cal     Complex calibration tone [Nx1], |z_cal| = 1
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section B.2

    f_B = f_A + Delta_f;
    phi0 = 2*pi * (f_B * theta + f_A * tau);
    z_cal = exp(1j * (2*pi * Delta_f * t + phi0));

end
