function test_cfo_phased_oracle()
% TEST_CFO_PHASED_ORACLE  Verify phase-derived and post-hoc oracle agreement.
%
%   Tests C22-C25: Proves that simulate_cfo_link_phased (authoritative,
%   station-specific phase functions) and simulate_cfo_link (post-hoc
%   oracle) produce identical beat FREQUENCIES for a range of parameters.
%
%   Also verifies:
%     C22: Agreement at nominal parameters
%     C23: Agreement across tau/theta/Delta_f sweep
%     C24: Zero CFO reproduces V1 beat frequency
%     C25: Constant phase terms are documented and finite

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;

    rel_tol = 1e-10;

    fprintf('  test_cfo_phased_oracle ...\n');

    %% C22: Nominal agreement
    tau = 5e-9;  theta = 100e-12;  Df = 100e3;

    res_phased = simulate_cfo_link_phased(cfg, tau, theta, Df);
    res_oracle = simulate_cfo_link(cfg, tau, theta, Df);

    f_AB_p = estimate_beat_phase_slope(res_phased.beat_AB, Fs).f_est;
    f_BA_p = estimate_beat_phase_slope(res_phased.beat_BA, Fs).f_est;
    f_AB_o = estimate_beat_phase_slope(res_oracle.beat_AB, Fs).f_est;
    f_BA_o = estimate_beat_phase_slope(res_oracle.beat_BA, Fs).f_est;

    assert(abs(f_AB_p - f_AB_o) / abs(f_AB_o) < rel_tol, ...
           'C22: f_AB phased vs oracle mismatch');
    assert(abs(f_BA_p - f_BA_o) / abs(f_BA_o) < rel_tol, ...
           'C22: f_BA phased vs oracle mismatch');

    % Also verify against analytical formula
    f_AB_theory = S*(tau + theta) + Df;
    f_BA_theory = S*(tau - theta) - Df;
    assert(abs(f_AB_p - f_AB_theory) / abs(f_AB_theory) < rel_tol, ...
           'C22: f_AB phased vs theory mismatch');
    assert(abs(f_BA_p - f_BA_theory) / abs(f_BA_theory) < rel_tol, ...
           'C22: f_BA phased vs theory mismatch');
    fprintf('    C22 PASS: Phased/oracle agreement at nominal\n');

    %% C23: Sweep across parameters
    cases = [
        5e-9,   100e-12,  100e3;
        10e-9,  0,        200e3;
        1e-9,   -50e-12, -75e3;
        5e-9,   500e-12,  1e6;
        20e-9,  -200e-12, 50e3;
        0,      0,        100e3;
    ];
    for k = 1:size(cases, 1)
        tc_tau = cases(k,1); tc_theta = cases(k,2); tc_Df = cases(k,3);
        rp = simulate_cfo_link_phased(cfg, tc_tau, tc_theta, tc_Df);
        ro = simulate_cfo_link(cfg, tc_tau, tc_theta, tc_Df);
        fp_AB = estimate_beat_phase_slope(rp.beat_AB, Fs).f_est;
        fo_AB = estimate_beat_phase_slope(ro.beat_AB, Fs).f_est;
        fp_BA = estimate_beat_phase_slope(rp.beat_BA, Fs).f_est;
        fo_BA = estimate_beat_phase_slope(ro.beat_BA, Fs).f_est;
        assert(abs(fp_AB - fo_AB) / (abs(fo_AB) + 1e-20) < rel_tol, ...
               'C23 case %d: f_AB mismatch', k);
        assert(abs(fp_BA - fo_BA) / (abs(fo_BA) + 1e-20) < rel_tol, ...
               'C23 case %d: f_BA mismatch', k);
    end
    fprintf('    C23 PASS: Phased/oracle sweep (%d cases)\n', size(cases,1));

    %% C24: Zero CFO = V1 beat frequency
    rp0 = simulate_cfo_link_phased(cfg, tau, theta, 0);
    f_AB_0 = estimate_beat_phase_slope(rp0.beat_AB, Fs).f_est;
    f_BA_0 = estimate_beat_phase_slope(rp0.beat_BA, Fs).f_est;
    f_AB_v1 = S * (tau + theta);
    f_BA_v1 = S * (tau - theta);
    assert(abs(f_AB_0 - f_AB_v1) / abs(f_AB_v1) < rel_tol, ...
           'C24: zero-CFO f_AB != V1');
    assert(abs(f_BA_0 - f_BA_v1) / abs(f_BA_v1) < rel_tol, ...
           'C24: zero-CFO f_BA != V1');
    fprintf('    C24 PASS: Zero CFO reproduces V1 beat frequency\n');

    %% C25: Constant phase terms are finite and documented
    assert(isfinite(res_phased.phi0_AB), 'C25: phi0_AB not finite');
    assert(isfinite(res_phased.phi0_BA), 'C25: phi0_BA not finite');
    % Verify phi0_AB matches analytical formula
    f_A = cfg.fc;  f_B = f_A + Df;
    phi0_AB_expected = 2*pi*(f_B*theta + f_A*tau) + pi*S*(theta^2 - tau^2);
    assert(abs(res_phased.phi0_AB - phi0_AB_expected) < 1e-6, ...
           'C25: phi0_AB formula mismatch');
    fprintf('    C25 PASS: Constant phase terms finite and correct\n');

    fprintf('  test_cfo_phased_oracle: ALL PASS\n');
end
