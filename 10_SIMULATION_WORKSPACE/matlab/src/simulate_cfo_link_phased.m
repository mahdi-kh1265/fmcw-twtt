function result = simulate_cfo_link_phased(cfg, tau, theta, Delta_f)
% SIMULATE_CFO_LINK_PHASED  Authoritative phase-derived CFO link model.
%
%   result = simulate_cfo_link_phased(cfg, tau, theta, Delta_f)
%
%   Constructs station-specific analytic phase functions and derives
%   the directional beat signals from the project's frozen mixer
%   convention z = LO .* conj(RX).
%
%   Station phase model:
%
%       T_A(t) = t                       (A is the reference clock)
%       T_B(t) = t + theta               (B offset by theta)
%
%       Phi_A(t) = 2*pi*f_A*T_A(t) + pi*S*T_A(t)^2
%       Phi_B(t) = 2*pi*f_B*T_B(t) + pi*S*T_B(t)^2
%
%   with Delta_f = f_B - f_A.
%
%   A->B direction (A transmits, B receives and dechirps):
%       LO  = station B's local chirp at time t:    Phi_B(t)
%       RX  = station A's signal delayed by tau:     Phi_A(t - tau)
%       Beat phase: Phi_AB(t) = Phi_B(t) - Phi_A(t - tau)
%
%   B->A direction (B transmits, A receives and dechirps):
%       LO  = station A's local chirp at time t:    Phi_A(t)
%       RX  = station B's signal delayed by tau:     Phi_B(t - tau)
%       Beat phase: Phi_BA(t) = Phi_A(t) - Phi_B(t - tau)
%
%   The carrier frequency f_A is set to cfg.fc (77 GHz nominal).
%   f_B = f_A + Delta_f.
%
%   Implementation: computes the analytic phase difference directly
%   (carrier-referenced algebraic equivalent), NOT a sampled full-RF
%   waveform. This avoids numerical conditioning issues from 77-GHz
%   sampling while remaining mathematically exact.
%
%   Resulting beat frequencies:
%       f_AB = S*(tau + theta) + Delta_f
%       f_BA = S*(tau - theta) - Delta_f
%
%   Constant phase terms (documented but not affecting frequency estimation):
%       phi0_AB = 2*pi*(f_B*theta + f_A*tau) + pi*S*(theta^2 - tau^2)
%       phi0_BA = -2*pi*(f_B*(theta - tau)) - pi*S*(tau - theta)^2
%
%   Inputs:
%       cfg      Configuration struct from make_default_params()
%       tau      One-way propagation delay [s]
%       theta    Relative clock epoch offset [s]
%       Delta_f  Carrier-frequency offset [Hz]  (= f_B - f_A)
%
%   Output:
%       result   Struct with fields:
%         .beat_AB       A->B beat signal [Nx1]
%         .beat_BA       B->A beat signal [Nx1]
%         .t             Time vector [Nx1] [s]
%         .f_AB_theory   Theoretical f_AB [Hz]
%         .f_BA_theory   Theoretical f_BA [Hz]
%         .phi0_AB       Constant phase in A->B beat [rad]
%         .phi0_BA       Constant phase in B->A beat [rad]
%         .tau           Injected tau (echo) [s]
%         .theta         Injected theta (echo) [s]
%         .Delta_f       Injected Delta_f (echo) [Hz]
%         .cfg           Configuration struct (echo)
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Sections A.1-A.5

    S  = cfg.S;
    Fs = cfg.Fs;
    N  = cfg.N;

    % Carrier frequencies
    f_A = cfg.fc;              % Station A carrier [Hz]
    f_B = f_A + Delta_f;       % Station B carrier [Hz]

    % Time vector
    t = (0:N-1).' / Fs;

    % ================================================================
    % A->B direction: A transmits, B receives after delay tau
    % ================================================================
    %
    % B's LO phase:     Phi_B(t)    = 2*pi*f_B*(t+theta) + pi*S*(t+theta)^2
    % A's RX phase:     Phi_A(t-tau) = 2*pi*f_A*(t-tau)   + pi*S*(t-tau)^2
    %
    % Beat phase = Phi_B(t) - Phi_A(t-tau)
    %
    % Carrier part:
    %   2*pi*f_B*(t+theta) - 2*pi*f_A*(t-tau)
    %   = 2*pi*Delta_f*t + 2*pi*(f_B*theta + f_A*tau)
    %
    % Chirp part:
    %   pi*S*(t+theta)^2 - pi*S*(t-tau)^2
    %   = pi*S*[2*(tau+theta)*t + (theta^2 - tau^2)]
    %   = 2*pi*S*(tau+theta)*t + pi*S*(theta^2 - tau^2)
    %
    % Combined:
    %   Phi_AB(t) = 2*pi*[S*(tau+theta) + Delta_f]*t
    %             + 2*pi*(f_B*theta + f_A*tau) + pi*S*(theta^2 - tau^2)

    f_AB = S*(tau + theta) + Delta_f;
    phi0_AB = 2*pi*(f_B*theta + f_A*tau) + pi*S*(theta^2 - tau^2);

    result.beat_AB = exp(1j * (2*pi*f_AB*t + phi0_AB));

    % ================================================================
    % B->A direction: B transmits, A receives after delay tau
    % ================================================================
    %
    % A's LO phase:     Phi_A(t)      = 2*pi*f_A*t + pi*S*t^2
    % B's RX phase:     Phi_B(t-tau)  = 2*pi*f_B*(t-tau+theta) + pi*S*(t-tau+theta)^2
    %
    % Beat phase = Phi_A(t) - Phi_B(t-tau)
    %
    % Carrier part:
    %   2*pi*f_A*t - 2*pi*f_B*(t - tau + theta)
    %   = -2*pi*Delta_f*t + 2*pi*f_B*(tau - theta)
    %
    % Chirp part:
    %   pi*S*t^2 - pi*S*(t - tau + theta)^2
    %   = pi*S*[2*(tau - theta)*t - (tau - theta)^2]
    %   = 2*pi*S*(tau - theta)*t - pi*S*(tau - theta)^2
    %
    % Combined:
    %   Phi_BA(t) = 2*pi*[S*(tau-theta) - Delta_f]*t
    %             + 2*pi*f_B*(tau - theta) - pi*S*(tau - theta)^2

    f_BA = S*(tau - theta) - Delta_f;
    phi0_BA = 2*pi*f_B*(tau - theta) - pi*S*(tau - theta)^2;

    result.beat_BA = exp(1j * (2*pi*f_BA*t + phi0_BA));

    % Metadata
    result.t          = t;
    result.f_AB_theory = f_AB;
    result.f_BA_theory = f_BA;
    result.phi0_AB    = phi0_AB;
    result.phi0_BA    = phi0_BA;
    result.tau        = tau;
    result.theta      = theta;
    result.Delta_f    = Delta_f;
    result.cfg        = cfg;

end
