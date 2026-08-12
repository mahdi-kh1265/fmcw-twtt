function test_updown_full()
% TEST_UPDOWN_FULL  Full two-direction up/down chirp test.
%
%   C20: A->B up/down -> delta_AB = tau + theta, Delta_f
%   C21: B->A up/down -> delta_BA = tau - theta, Delta_f
%   C30: Combine both directions to recover tau and theta independently
%
%   This demonstrates the complete Roehr-lineage pipeline.

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;
    N   = cfg.N;
    t   = (0:N-1).' / Fs;

    tau   = 5e-9;
    theta = 100e-12;
    Df    = 100e3;

    delta_AB = tau + theta;
    delta_BA = tau - theta;

    rel_tol   = 1e-10;
    abs_tol_s = 1e-14;

    fprintf('  test_updown_full ...\n');

    cfg_down = cfg;
    cfg_down.S = -S;

    %% C20: A->B direction
    % Up chirp
    res_up_AB = simulate_cfo_link_phased(cfg, tau, theta, Df);
    f_up_AB = estimate_beat_phase_slope(res_up_AB.beat_AB, Fs).f_est;
    % Down chirp
    res_dn_AB = simulate_cfo_link_phased(cfg_down, tau, theta, Df);
    f_dn_AB = estimate_beat_phase_slope(res_dn_AB.beat_AB, Fs).f_est;

    [Df_hat_AB, delta_AB_hat] = solve_twtt_updown(f_up_AB, f_dn_AB, S);
    assert(abs(Df_hat_AB - Df) / abs(Df) < rel_tol, ...
           'C20: A->B Df recovery mismatch');
    assert(abs(delta_AB_hat - delta_AB) / abs(delta_AB) < rel_tol, ...
           'C20: A->B delta recovery mismatch');
    fprintf('    C20 PASS: A->B: delta_AB = %.3f ns, Df = %.1f kHz\n', ...
            delta_AB_hat*1e9, Df_hat_AB/1e3);

    %% C21: B->A direction
    f_up_BA = estimate_beat_phase_slope(res_up_AB.beat_BA, Fs).f_est;
    f_dn_BA = estimate_beat_phase_slope(res_dn_AB.beat_BA, Fs).f_est;

    % For B->A, f_BA = S*(tau-theta) - Df, with down-chirp: f_BA_dn = -S*(tau-theta) - Df
    % solve_twtt_updown expects f_up = +S*delta + Df, f_down = -S*delta + Df
    % But for BA direction, f_up_BA = S*(tau-theta) - Df, f_dn_BA = -S*(tau-theta) - Df
    % The CFO sign is flipped vs the AB convention.
    % solve_twtt_updown assumes: sum = 2*Df, diff = 2*S*delta.
    % For BA: sum = f_up_BA + f_dn_BA = -2*Df, diff = f_up_BA - f_dn_BA = 2*S*delta_BA
    % So: Df_hat = sum/2 = -Df, delta_hat = diff/(2*S) = delta_BA
    [Df_hat_BA, delta_BA_hat] = solve_twtt_updown(f_up_BA, f_dn_BA, S);
    assert(abs(Df_hat_BA - (-Df)) / abs(Df) < rel_tol, ...
           'C21: B->A Df recovery mismatch (expect -Df)');
    assert(abs(delta_BA_hat - delta_BA) / abs(delta_BA) < rel_tol, ...
           'C21: B->A delta recovery mismatch');
    fprintf('    C21 PASS: B->A: delta_BA = %.3f ns, Df = %.1f kHz\n', ...
            delta_BA_hat*1e9, Df_hat_BA/1e3);

    %% C30: Combine both directions to recover tau and theta
    tau_hat   = (delta_AB_hat + delta_BA_hat) / 2;
    theta_hat = (delta_AB_hat - delta_BA_hat) / 2;

    assert(abs(tau_hat - tau) < abs_tol_s, ...
           'C30: tau recovery from two-direction up/down: err = %.2e', abs(tau_hat - tau));
    assert(abs(theta_hat - theta) < abs_tol_s, ...
           'C30: theta recovery from two-direction up/down: err = %.2e', abs(theta_hat - theta));
    fprintf('    C30 PASS: tau = %.3f ns, theta = %.1f ps (from two-direction up/down)\n', ...
            tau_hat*1e9, theta_hat*1e12);

    fprintf('  test_updown_full: ALL PASS\n');
end
