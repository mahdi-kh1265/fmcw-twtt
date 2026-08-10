function test_sign_convention()
% TEST_SIGN_CONVENTION  T11: slope scaling, T12: conjugation reversal.
%
%   T11 tolerance: |f2/f1 - 2| / 2 < 1e-10
%   T12 tolerance: |f_swap + f_normal| < 1e-6 Hz

    cfg = make_default_params();
    S  = cfg.S;
    Fs = cfg.Fs;
    delta = 5e-9;

    % --- T11: Slope scaling (S -> 2S => f_hat doubles) ---
    link1 = simulate_ideal_link(cfg, delta);
    est1  = estimate_beat_phase_slope(link1.beat, Fs);

    cfg2   = cfg;
    cfg2.S = 2 * cfg.S;
    link2  = simulate_ideal_link(cfg2, delta);
    est2   = estimate_beat_phase_slope(link2.beat, Fs);

    ratio   = est2.f_est / est1.f_est;
    rel_err = abs(ratio - 2) / 2;
    assert(rel_err < 1e-10, ...
        sprintf('T11 FAIL: f2/f1 = %.12f, expected 2.0, rel_err=%.2e', ...
        ratio, rel_err));

    % --- T12: Conjugation reversal (z = rx.*conj(tx) => sign flip) ---
    link = simulate_ideal_link(cfg, delta);
    est_normal = estimate_beat_phase_slope(link.beat, Fs);

    beat_swap  = link.rx .* conj(link.tx);   % reversed convention
    est_swap   = estimate_beat_phase_slope(beat_swap, Fs);

    sum_abs = abs(est_swap.f_est + est_normal.f_est);
    assert(sum_abs < 1e-6, ...
        sprintf('T12 FAIL: f_swap=%.6f + f_normal=%.6f = %.2e (expected ~0)', ...
        est_swap.f_est, est_normal.f_est, sum_abs));

    fprintf('  test_sign_convention: T11-T12 PASSED\n');
end
