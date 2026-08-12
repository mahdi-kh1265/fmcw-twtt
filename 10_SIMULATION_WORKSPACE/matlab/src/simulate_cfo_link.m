function result = simulate_cfo_link(cfg, tau, theta, Delta_f)
% SIMULATE_CFO_LINK  Post-hoc closed-form CFO oracle.
%
%   result = simulate_cfo_link(cfg, tau, theta, Delta_f)
%
%   Generates V0/V1 ideal beats then applies CFO as a post-dechirp
%   frequency shift.  This is a correct closed-form shortcut that
%   produces identical beat frequencies to the authoritative phase-
%   derived model (simulate_cfo_link_phased), but does NOT construct
%   station-specific phase functions.  Retained as an independent
%   oracle for cross-validation.
%
%   See simulate_cfo_link_phased for the authoritative model.
%
%   Key properties:
%       f_AB + f_BA = 2*S*tau            (CFO cancels in sum)
%       f_AB - f_BA = 2*S*theta + 2*Delta_f  (CFO contaminates difference)
%
%   Inputs:
%       cfg      Configuration struct from make_default_params()
%       tau      One-way propagation delay [s]
%       theta    Relative clock epoch offset [s]
%       Delta_f  Carrier-frequency offset [Hz]  (= f_B - f_A)
%
%   Output:
%       result   Struct with fields:
%         .link_AB       A->B link struct (from simulate_ideal_link)
%         .link_BA       B->A link struct (from simulate_ideal_link)
%         .beat_AB       CFO-modified A->B beat [Nx1]
%         .beat_BA       CFO-modified B->A beat [Nx1]
%         .f_AB_theory   Theoretical f_AB = S*(tau+theta) + Delta_f [Hz]
%         .f_BA_theory   Theoretical f_BA = S*(tau-theta) - Delta_f [Hz]
%         .tau            Injected tau (echo) [s]
%         .theta          Injected theta (echo) [s]
%         .Delta_f        Injected Delta_f (echo) [Hz]
%         .cfg            Configuration struct (echo)
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section E.3

    % V0/V1 ideal links with effective delays
    delta_AB = tau + theta;
    delta_BA = tau - theta;

    result.link_AB = simulate_ideal_link(cfg, delta_AB);
    result.link_BA = simulate_ideal_link(cfg, delta_BA);

    % Time vector (same for both)
    t = result.link_AB.t;

    % Apply CFO to each direction
    result.beat_AB = apply_cfo(result.link_AB.beat, t, Delta_f, 'AB');
    result.beat_BA = apply_cfo(result.link_BA.beat, t, Delta_f, 'BA');

    % Theoretical beat frequencies under CFO
    result.f_AB_theory = cfg.S * delta_AB + Delta_f;
    result.f_BA_theory = cfg.S * delta_BA - Delta_f;

    % Echo inputs
    result.tau     = tau;
    result.theta   = theta;
    result.Delta_f = Delta_f;
    result.cfg     = cfg;

end
