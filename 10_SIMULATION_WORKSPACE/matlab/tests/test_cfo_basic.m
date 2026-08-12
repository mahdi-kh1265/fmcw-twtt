function test_cfo_basic()
% TEST_CFO_BASIC  Core CFO model tests C01-C06, C10, C17, C18.
%
%   Validates that:
%     - Zero CFO reproduces V1 (C01)
%     - Positive/negative CFO produce correct beat frequencies (C02-C04)
%     - Zero-delay with CFO works (C05)
%     - Multiple parameter combinations match analytics (C06)
%     - CFO sum always cancels in f_AB + f_BA (C10)
%     - apply_cfo with zero CFO is identity (C17)
%     - Apply then correct is round-trip identity (C18)
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section F.1

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;

    % Tolerances (same as V0/V1 spec F.3)
    rel_tol = 1e-10;
    abs_tol_s = 1e-14;  % seconds

    fprintf('  test_cfo_basic ...\n');

    %% C01: Zero CFO reproduces V1
    tau   = 5e-9;
    theta = 100e-12;
    Df    = 0;

    res = simulate_cfo_link(cfg, tau, theta, Df);
    f_AB = estimate_beat_phase_slope(res.beat_AB, Fs).f_est;
    f_BA = estimate_beat_phase_slope(res.beat_BA, Fs).f_est;
    [tau_hat, theta_hat] = solve_twtt(f_AB, f_BA, S);

    assert(abs(tau_hat - tau) < abs_tol_s, ...
           'C01: tau mismatch: got %.6e, expected %.6e', tau_hat, tau);
    assert(abs(theta_hat - theta) < abs_tol_s, ...
           'C01: theta mismatch: got %.6e, expected %.6e', theta_hat, theta);

    % Also verify beats match V1 link directly
    link_AB_v1 = simulate_ideal_link(cfg, tau + theta);
    link_BA_v1 = simulate_ideal_link(cfg, tau - theta);
    assert(max(abs(res.beat_AB - link_AB_v1.beat)) < 1e-14, ...
           'C01: AB beat not identical to V1');
    assert(max(abs(res.beat_BA - link_BA_v1.beat)) < 1e-14, ...
           'C01: BA beat not identical to V1');
    fprintf('    C01 PASS: Zero CFO reproduces V1\n');

    %% C02: Positive CFO, A->B beat
    Df = 100e3;  % 100 kHz
    res = simulate_cfo_link(cfg, tau, theta, Df);
    f_AB = estimate_beat_phase_slope(res.beat_AB, Fs).f_est;
    f_AB_theory = S*(tau + theta) + Df;
    assert(abs(f_AB - f_AB_theory) / abs(f_AB_theory) < rel_tol, ...
           'C02: f_AB mismatch: got %.6f, expected %.6f Hz', f_AB, f_AB_theory);
    fprintf('    C02 PASS: Positive CFO A->B beat\n');

    %% C03: Positive CFO, B->A beat
    f_BA = estimate_beat_phase_slope(res.beat_BA, Fs).f_est;
    f_BA_theory = S*(tau - theta) - Df;
    assert(abs(f_BA - f_BA_theory) / abs(f_BA_theory) < rel_tol, ...
           'C03: f_BA mismatch: got %.6f, expected %.6f Hz', f_BA, f_BA_theory);
    fprintf('    C03 PASS: Positive CFO B->A beat\n');

    %% C04: Negative CFO
    Df_neg = -100e3;
    res_neg = simulate_cfo_link(cfg, tau, theta, Df_neg);
    f_AB_neg = estimate_beat_phase_slope(res_neg.beat_AB, Fs).f_est;
    f_BA_neg = estimate_beat_phase_slope(res_neg.beat_BA, Fs).f_est;
    f_AB_neg_theory = S*(tau + theta) + Df_neg;
    f_BA_neg_theory = S*(tau - theta) - Df_neg;
    assert(abs(f_AB_neg - f_AB_neg_theory) / abs(f_AB_neg_theory) < rel_tol, ...
           'C04: f_AB neg CFO mismatch');
    assert(abs(f_BA_neg - f_BA_neg_theory) / abs(f_BA_neg_theory) < rel_tol, ...
           'C04: f_BA neg CFO mismatch');
    fprintf('    C04 PASS: Negative CFO\n');

    %% C05: Zero delay with CFO
    res_zero = simulate_cfo_link(cfg, 0, 0, 50e3);
    f_AB_zero = estimate_beat_phase_slope(res_zero.beat_AB, Fs).f_est;
    f_BA_zero = estimate_beat_phase_slope(res_zero.beat_BA, Fs).f_est;
    assert(abs(f_AB_zero - 50e3) / 50e3 < rel_tol, ...
           'C05: f_AB with tau=theta=0 should be Delta_f');
    assert(abs(f_BA_zero - (-50e3)) / 50e3 < rel_tol, ...
           'C05: f_BA with tau=theta=0 should be -Delta_f');
    fprintf('    C05 PASS: Zero delay with CFO\n');

    %% C06: Multiple parameter combinations
    test_cases = [
        5e-9,   100e-12,   50e3;
        10e-9,  0,         200e3;
        1e-9,   -50e-12,   -75e3;
        5e-9,   500e-12,   1e6;
    ];
    for k = 1:size(test_cases, 1)
        tc_tau   = test_cases(k, 1);
        tc_theta = test_cases(k, 2);
        tc_Df    = test_cases(k, 3);
        tc_res   = simulate_cfo_link(cfg, tc_tau, tc_theta, tc_Df);
        tc_fAB   = estimate_beat_phase_slope(tc_res.beat_AB, Fs).f_est;
        tc_fBA   = estimate_beat_phase_slope(tc_res.beat_BA, Fs).f_est;
        tc_fAB_th = S*(tc_tau + tc_theta) + tc_Df;
        tc_fBA_th = S*(tc_tau - tc_theta) - tc_Df;
        assert(abs(tc_fAB - tc_fAB_th) / abs(tc_fAB_th) < rel_tol, ...
               'C06 case %d: f_AB mismatch', k);
        assert(abs(tc_fBA - tc_fBA_th) / abs(tc_fBA_th) < rel_tol, ...
               'C06 case %d: f_BA mismatch', k);
    end
    fprintf('    C06 PASS: Multiple parameter combinations (%d cases)\n', ...
            size(test_cases, 1));

    %% C10: CFO sum cancellation
    Df_vals = [10, 100, 1e3, 10e3, 100e3, 1e6];
    for k = 1:length(Df_vals)
        tc_res  = simulate_cfo_link(cfg, tau, theta, Df_vals(k));
        tc_fAB  = estimate_beat_phase_slope(tc_res.beat_AB, Fs).f_est;
        tc_fBA  = estimate_beat_phase_slope(tc_res.beat_BA, Fs).f_est;
        tc_sum  = tc_fAB + tc_fBA;
        tc_sum_theory = 2 * S * tau;
        assert(abs(tc_sum - tc_sum_theory) / abs(tc_sum_theory) < rel_tol, ...
               'C10: sum cancellation failed at Df = %.0f Hz', Df_vals(k));
    end
    fprintf('    C10 PASS: CFO sum cancellation (%d values)\n', length(Df_vals));

    %% C17: apply_cfo with zero CFO is identity
    t_vec = (0:cfg.N-1).' / Fs;
    test_beat = exp(1j * 2*pi * 12345 * t_vec);  % arbitrary tone
    beat_out  = apply_cfo(test_beat, t_vec, 0, 'AB');
    assert(max(abs(beat_out - test_beat)) < 1e-14, ...
           'C17: apply_cfo with Df=0 should be identity');
    beat_out_ba = apply_cfo(test_beat, t_vec, 0, 'BA');
    assert(max(abs(beat_out_ba - test_beat)) < 1e-14, ...
           'C17: apply_cfo BA with Df=0 should be identity');
    fprintf('    C17 PASS: Zero CFO is identity\n');

    %% C18: Apply then correct is round-trip
    Df_rt = 77777;
    beat_with_cfo = apply_cfo(test_beat, t_vec, Df_rt, 'AB');
    beat_restored = correct_cfo(beat_with_cfo, t_vec, Df_rt, 'AB');
    assert(max(abs(beat_restored - test_beat)) < 1e-10, ...
           'C18: apply then correct AB round-trip failed');

    beat_with_cfo_ba = apply_cfo(test_beat, t_vec, Df_rt, 'BA');
    beat_restored_ba = correct_cfo(beat_with_cfo_ba, t_vec, Df_rt, 'BA');
    assert(max(abs(beat_restored_ba - test_beat)) < 1e-10, ...
           'C18: apply then correct BA round-trip failed');
    fprintf('    C18 PASS: Apply/correct round-trip\n');

    fprintf('  test_cfo_basic: ALL PASS\n');
end
