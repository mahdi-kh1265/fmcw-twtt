function test_waveform_closedform()
% TEST_WAVEFORM_CLOSEDFORM  T13: dechirped beat matches closed-form expression.
%
%   For s(t) = exp(j*pi*S*t^2),  r(t) = exp(j*pi*S*(t-delta)^2):
%
%       z(t) = s(t).*conj(r(t))
%            = exp(j*(2*pi*S*delta*t - pi*S*delta^2))
%
%   This test catches waveform/model bugs that estimator-only tests
%   might miss if an estimator bug compensated for them.
%
%   Tolerance: max|z_sim - z_expected| < 1e-10  (spec Section F.3)

    cfg   = make_default_params();
    S     = cfg.S;
    delta = 5e-9;

    link = simulate_ideal_link(cfg, delta);
    t    = link.t;

    % Closed-form expected beat
    z_expected = exp(1j * (2*pi*S*delta*t - pi*S*delta^2));

    % Sample-by-sample comparison
    max_err = max(abs(link.beat - z_expected));
    assert(max_err < 1e-10, ...
        sprintf('T13 FAIL: max|z_sim - z_expected| = %.2e', max_err));

    fprintf('  test_waveform_closedform: T13 PASSED\n');
end
