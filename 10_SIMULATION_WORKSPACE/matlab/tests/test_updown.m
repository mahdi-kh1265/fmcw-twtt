function test_updown()
% TEST_UPDOWN  Up/down chirp CFO+delay separation tests C11-C12.
%
%   Validates the Roehr 2007 approach:
%     - Up/down chirps with CFO recover Delta_f exactly (C11)
%     - Up/down chirps with CFO recover effective delay exactly (C12)
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section F.1

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;

    tau   = 5e-9;
    theta = 100e-12;
    Df    = 100e3;
    delta = tau + theta;  % effective A->B delay

    rel_tol = 1e-10;

    fprintf('  test_updown ...\n');

    %% Generate up-chirp (+S) beat with CFO
    link_up = simulate_ideal_link(cfg, delta);
    t = link_up.t;
    beat_up = apply_cfo(link_up.beat, t, Df, 'AB');
    f_up = estimate_beat_phase_slope(beat_up, Fs).f_est;

    %% Generate down-chirp (-S) beat with CFO
    cfg_down = cfg;
    cfg_down.S = -S;
    link_down = simulate_ideal_link(cfg_down, delta);
    beat_down = apply_cfo(link_down.beat, t, Df, 'AB');
    f_down = estimate_beat_phase_slope(beat_down, Fs).f_est;

    %% Verify individual beat frequencies
    f_up_theory   = +S * delta + Df;
    f_down_theory = -S * delta + Df;
    assert(abs(f_up - f_up_theory) / abs(f_up_theory) < rel_tol, ...
           'C11/C12: f_up mismatch');
    assert(abs(f_down - f_down_theory) / abs(f_down_theory) < rel_tol, ...
           'C11/C12: f_down mismatch');

    %% C11: Up/down CFO recovery
    [Df_hat, delta_hat] = solve_twtt_updown(f_up, f_down, S);
    assert(abs(Df_hat - Df) / abs(Df) < rel_tol, ...
           'C11: CFO recovery mismatch: got %.6f, expected %.6f Hz', Df_hat, Df);
    fprintf('    C11 PASS: Up/down CFO recovery = %.1f kHz\n', Df_hat/1e3);

    %% C12: Up/down delay recovery
    assert(abs(delta_hat - delta) / abs(delta) < rel_tol, ...
           'C12: delay recovery mismatch: got %.6e, expected %.6e s', delta_hat, delta);
    fprintf('    C12 PASS: Up/down delay recovery = %.3f ns\n', delta_hat*1e9);

    %% Additional: sweep CFO values
    % CFO must stay within Nyquist (Fs/2 = 5 MHz). Baseline beats ~150 kHz.
    % Cap sweep at 2 MHz for clear safety margin.
    Df_sweep = [10, 1e3, 50e3, 500e3, 2e6];
    for k = 1:length(Df_sweep)
        Df_k = Df_sweep(k);

        beat_up_k = apply_cfo(link_up.beat, t, Df_k, 'AB');
        f_up_k = estimate_beat_phase_slope(beat_up_k, Fs).f_est;

        beat_down_k = apply_cfo(link_down.beat, t, Df_k, 'AB');
        f_down_k = estimate_beat_phase_slope(beat_down_k, Fs).f_est;

        [Df_hat_k, delta_hat_k] = solve_twtt_updown(f_up_k, f_down_k, S);
        assert(abs(Df_hat_k - Df_k) / abs(Df_k) < rel_tol, ...
               'C11 sweep: CFO mismatch at Df = %.0f Hz', Df_k);
        assert(abs(delta_hat_k - delta) / abs(delta) < rel_tol, ...
               'C12 sweep: delay mismatch at Df = %.0f Hz', Df_k);
    end
    fprintf('    C11/C12 sweep PASS: %d CFO values\n', length(Df_sweep));

    fprintf('  test_updown: ALL PASS\n');
end
