% demo_v1_two_way.m
% V1: Ideal reciprocal two-way FMCW timing demonstration.
%
% Generates:
%   figures/fig02_v1_two_way.png     -- TWTT summary
%   figures/fig04_theta_recovery.png -- clock-offset recovery sweep
%   results/saeed_morning_summary.md -- PM-facing report
%
% Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections C, D, G, H

%% Setup
cfg   = make_default_params();
S     = cfg.S;
Fs    = cfg.Fs;
N     = cfg.N;
Tobs  = N / Fs;
tau   = 5e-9;       % 5 ns propagation delay
theta = 100e-12;    % 100 ps clock offset

%% Effective delays (derived in spec A.11)
delta_AB = tau + theta;
delta_BA = tau - theta;

%% Run two ideal links (V1 reuses simulate_ideal_link exactly twice)
link_AB = simulate_ideal_link(cfg, delta_AB);
link_BA = simulate_ideal_link(cfg, delta_BA);

%% Estimate beat frequencies
fft_AB   = estimate_beat_fft(link_AB.beat, Fs);
fft_BA   = estimate_beat_fft(link_BA.beat, Fs);
phase_AB = estimate_beat_phase_slope(link_AB.beat, Fs);
phase_BA = estimate_beat_phase_slope(link_BA.beat, Fs);

%% Recover tau and theta
[tau_hat, theta_hat] = solve_twtt(phase_AB.f_est, phase_BA.f_est, S);

%% Print V1 results
fprintf('\n');
fprintf('====================================================\n');
fprintf('  FMCW V1 -- IDEAL TWO-WAY TIMING\n');
fprintf('====================================================\n');
fprintf('  Slope S:                     %.3f MHz/us\n',     S / 1e12);
fprintf('  Sample rate Fs:              %.0f MHz\n',         Fs / 1e6);
fprintf('  Samples N:                   %d\n',               N);
fprintf('  Observation time Tobs:       %.1f us\n',          Tobs * 1e6);
fprintf('  FFT bin spacing:             %.4f kHz\n',         fft_AB.df / 1e3);
fprintf('  ----\n');
fprintf('  Injected propagation delay:  %.3f ns\n',          tau * 1e9);
fprintf('  Injected clock offset:       %.1f ps\n',          theta * 1e12);
fprintf('  ----\n');
fprintf('  Theoretical f_AB:            %.1f Hz\n',          link_AB.fb_theory);
fprintf('  Estimated f_AB:              %.1f Hz\n',          phase_AB.f_est);
fprintf('  Theoretical f_BA:            %.1f Hz\n',          link_BA.fb_theory);
fprintf('  Estimated f_BA:              %.1f Hz\n',          phase_BA.f_est);
fprintf('  f_AB - f_BA (theory):        %.1f Hz\n',          link_AB.fb_theory - link_BA.fb_theory);
fprintf('  ----\n');
fprintf('  Recovered propagation delay: %.9f ns\n',          tau_hat * 1e9);
fprintf('  Propagation-delay error:     %.2e s\n',           abs(tau_hat - tau));
fprintf('  Recovered clock offset:      %.3f ps\n',          theta_hat * 1e12);
fprintf('  Clock-offset error:          %.2e s\n',           abs(theta_hat - theta));
fprintf('  ----\n');
fprintf('  CONDITIONS: IDEAL, noise-free, matched oscillators\n');
fprintf('====================================================\n\n');

%% Output directories
script_dir  = fileparts(mfilename('fullpath'));
fig_dir     = fullfile(script_dir, '..', 'figures');
results_dir = fullfile(script_dir, '..', 'results');
if ~exist(fig_dir, 'dir'),     mkdir(fig_dir);     end
if ~exist(results_dir, 'dir'), mkdir(results_dir); end

%% ========== Figure 2: Two-Way FMCW / TWTT Summary ==========
fig2 = figure('Position', [100 100 900 550], 'Color', 'w', 'Visible', 'off');

% --- Left: overlaid beat spectra ---
subplot(1,2,1);
N_half   = floor(N/2);
freq_kHz = fft_AB.freq_axis(1:N_half+1) / 1e3;
mag_AB   = 20*log10(fft_AB.spectrum_mag(1:N_half+1) / ...
           max(fft_AB.spectrum_mag) + 1e-30);
mag_BA   = 20*log10(fft_BA.spectrum_mag(1:N_half+1) / ...
           max(fft_BA.spectrum_mag) + 1e-30);

plot(freq_kHz, mag_AB, 'b-', 'LineWidth', 1.2); hold on;
plot(freq_kHz, mag_BA, 'r-', 'LineWidth', 1.2);
xline(phase_AB.f_est/1e3, 'b--', 'LineWidth', 1);
xline(phase_BA.f_est/1e3, 'r--', 'LineWidth', 1);

xlabel('Frequency [kHz]', 'FontSize', 11);
ylabel('Magnitude [dB]', 'FontSize', 11);
title('Directional Beat Spectra', 'FontSize', 12);
legend(sprintf('A\\rightarrowB: %.1f Hz', phase_AB.f_est), ...
       sprintf('B\\rightarrowA: %.1f Hz', phase_BA.f_est), ...
       'Location', 'northeast');
xlim([0 freq_kHz(end)]);
ylim([-60 5]);
grid on; set(gca, 'FontSize', 10);

% --- Right: recovery summary ---
subplot(1,2,2);
axis off;
summary = {
    '\bf{Two-Way Recovery}', ...
    '', ...
    sprintf('\\tau_{hat}   = (f_{AB} + f_{BA}) / (2S)'), ...
    sprintf('\\theta_{hat} = (f_{AB} - f_{BA}) / (2S)'), ...
    '', ...
    sprintf('Injected \\tau:     %.3f ns', tau*1e9), ...
    sprintf('Injected \\theta:   %.1f ps', theta*1e12), ...
    '', ...
    sprintf('f_{AB} est:  %.1f Hz', phase_AB.f_est), ...
    sprintf('f_{BA} est:  %.1f Hz', phase_BA.f_est), ...
    '', ...
    sprintf('Recovered \\tau:    %.9f ns', tau_hat*1e9), ...
    sprintf('Recovered \\theta:  %.3f ps', theta_hat*1e12), ...
    '', ...
    sprintf('\\tau error:    %.1e s', abs(tau_hat - tau)), ...
    sprintf('\\theta error:  %.1e s', abs(theta_hat - theta)), ...
    '', ...
    '\bf{IDEAL -- noise-free, matched oscillators,}', ...
    '\bf{reciprocal path}'
};
text(0.05, 0.95, summary, 'Units', 'normalized', ...
     'VerticalAlignment', 'top', 'FontSize', 10, ...
     'FontName', 'FixedWidth', 'Interpreter', 'tex');

fig2_title = sprintf('V1 TWTT:  tau = %.1f ns,  theta = %.0f ps,  S = %.3f MHz/us', ...
        tau*1e9, theta*1e12, S/1e12);
try
    sgtitle(fig2_title, 'FontSize', 13, 'FontWeight', 'bold');
catch
    % sgtitle unavailable (Octave / older MATLAB): use annotation instead
    annotation('textbox', [0.1 0.93 0.8 0.06], 'String', fig2_title, ...
               'FontSize', 13, 'FontWeight', 'bold', ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

print(fig2, fullfile(fig_dir, 'fig02_v1_two_way.png'), '-dpng', '-r300');
try exportgraphics(fig2, fullfile(fig_dir, 'fig02_v1_two_way.pdf'), ...
                   'ContentType', 'vector'); catch, end
close(fig2);
fprintf('  Saved: figures/fig02_v1_two_way.png\n');

%% ========== Figure 4: Clock-Offset Recovery Sweep ==========
theta_vals = linspace(-1e-9, 1e-9, 41);
theta_recovered = zeros(size(theta_vals));

for i = 1:length(theta_vals)
    th = theta_vals(i);
    lAB = simulate_ideal_link(cfg, tau + th);
    lBA = simulate_ideal_link(cfg, tau - th);
    eAB = estimate_beat_phase_slope(lAB.beat, Fs);
    eBA = estimate_beat_phase_slope(lBA.beat, Fs);
    [~, theta_recovered(i)] = solve_twtt(eAB.f_est, eBA.f_est, S);
end

fig4 = figure('Position', [100 100 800 500], 'Color', 'w', 'Visible', 'off');

subplot(2,1,1);
plot(theta_vals*1e12, theta_recovered*1e12, 'bo', 'MarkerSize', 5); hold on;
plot(theta_vals*1e12, theta_vals*1e12, 'k--', 'LineWidth', 1);
% Mark specific points
markers = [-1000 -100 -10 10 100 1000];
for m = markers
    idx = find(abs(theta_vals*1e12 - m) < 0.1, 1);
    if ~isempty(idx)
        plot(theta_vals(idx)*1e12, theta_recovered(idx)*1e12, ...
             'rs', 'MarkerSize', 9, 'MarkerFaceColor', 'r');
    end
end
xlabel('Injected \theta [ps]', 'FontSize', 11);
ylabel('Recovered \theta_{hat} [ps]', 'FontSize', 11);
title(sprintf('V1 Clock-Offset Recovery (%s = %.1f ns)   IDEAL -- noise-free', ...
      '\tau', tau*1e9), 'FontSize', 12);
legend('Recovered', 'Identity', 'Location', 'northwest');
grid on; set(gca, 'FontSize', 10);

subplot(2,1,2);
residual_ps = (theta_recovered - theta_vals) * 1e12;
plot(theta_vals*1e12, residual_ps, 'ko-', 'MarkerSize', 4, 'LineWidth', 1);
xlabel('Injected \theta [ps]', 'FontSize', 11);
ylabel('Residual \theta_{hat} - \theta [ps]', 'FontSize', 11);
title('Recovery Residual', 'FontSize', 12);
grid on; set(gca, 'FontSize', 10);

print(fig4, fullfile(fig_dir, 'fig04_theta_recovery.png'), '-dpng', '-r300');
try exportgraphics(fig4, fullfile(fig_dir, 'fig04_theta_recovery.pdf'), ...
                   'ContentType', 'vector'); catch, end
close(fig4);
fprintf('  Saved: figures/fig04_theta_recovery.png\n');

%% ========== Morning Summary ==========
summary_path = fullfile(results_dir, 'saeed_morning_summary.md');
fid = fopen(summary_path, 'w');

fprintf(fid, '# FMCW Two-Way Time Transfer -- V0/V1 Simulation Results\n\n');
fprintf(fid, '**Date:** %s\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '**Status:** IDEAL / NOISE-FREE simulation only\n\n');
fprintf(fid, '---\n\n');

fprintf(fid, '## 1. Objective\n\n');
fprintf(fid, 'Demonstrate that FMCW dechirping converts sub-nanosecond propagation delay\n');
fprintf(fid, 'and picosecond clock offset into easily estimated low-frequency beats, and\n');
fprintf(fid, 'that two-way sum/difference algebra recovers both quantities exactly under\n');
fprintf(fid, 'ideal conditions.\n\n');

fprintf(fid, '## 2. V0 Single-Link Result\n\n');
fprintf(fid, '| Quantity | Value |\n');
fprintf(fid, '|---|---|\n');
fprintf(fid, '| Injected delay | %.3f ns |\n', delta * 1e9);
v0link = simulate_ideal_link(cfg, delta);
v0est  = estimate_beat_phase_slope(v0link.beat, Fs);
v0dhat = v0est.f_est / S;
fprintf(fid, '| Theoretical f_b | %.1f Hz |\n', v0link.fb_theory);
fprintf(fid, '| Estimated f_b | %.1f Hz |\n', v0est.f_est);
fprintf(fid, '| Recovered delay | %.9f ns |\n', v0dhat * 1e9);
fprintf(fid, '| Delay error | %.1e s |\n\n', abs(v0dhat - delta));

fprintf(fid, '## 3. V1 Two-Way Result\n\n');
fprintf(fid, '| Quantity | Value |\n');
fprintf(fid, '|---|---|\n');
fprintf(fid, '| Injected tau | %.3f ns |\n', tau * 1e9);
fprintf(fid, '| Injected theta | %.1f ps |\n', theta * 1e12);
fprintf(fid, '| Estimated f_AB | %.1f Hz |\n', phase_AB.f_est);
fprintf(fid, '| Estimated f_BA | %.1f Hz |\n', phase_BA.f_est);
fprintf(fid, '| f_AB - f_BA | %.1f Hz |\n', phase_AB.f_est - phase_BA.f_est);
fprintf(fid, '| Recovered tau | %.9f ns |\n', tau_hat * 1e9);
fprintf(fid, '| Recovered theta | %.3f ps |\n', theta_hat * 1e12);
fprintf(fid, '| tau error | %.1e s |\n', abs(tau_hat - tau));
fprintf(fid, '| theta error | %.1e s |\n\n', abs(theta_hat - theta));

fprintf(fid, '## 4. Model Assumptions\n\n');
fprintf(fid, 'All V0/V1 results assume:\n\n');
fprintf(fid, '- Identical chirp slopes at both stations (no slope mismatch)\n');
fprintf(fid, '- Zero carrier-frequency offset (no independent oscillator drift)\n');
fprintf(fid, '- Zero clock skew (constant theta, no time-varying drift)\n');
fprintf(fid, '- Zero phase noise\n');
fprintf(fid, '- No additive noise (infinite SNR)\n');
fprintf(fid, '- No ADC quantization effects\n');
fprintf(fid, '- No multipath\n');
fprintf(fid, '- No TX/RX group-delay asymmetry\n');
fprintf(fid, '- Reciprocal propagation path (same tau in both directions)\n');
fprintf(fid, '- No chirp ramp nonlinearity\n');
fprintf(fid, '- Analytic (not integer-sample) delay model\n\n');

fprintf(fid, '## 5. Numerical Parameters\n\n');
fprintf(fid, '| Parameter | Value |\n');
fprintf(fid, '|---|---|\n');
fprintf(fid, '| Chirp slope S | %.3f MHz/us = %.4e Hz/s |\n', S/1e12, S);
fprintf(fid, '| Sample rate Fs | %.0f MHz |\n', Fs/1e6);
fprintf(fid, '| Samples N | %d |\n', N);
fprintf(fid, '| Observation time Tobs | %.1f us |\n', Tobs*1e6);
fprintf(fid, '| FFT bin spacing | %.4f kHz |\n\n', fft_AB.df/1e3);

fprintf(fid, '## 6. Equations\n\n');
fprintf(fid, '```\n');
fprintf(fid, 'Baseband chirp:   s(t) = exp(j * pi * S * t^2)\n');
fprintf(fid, 'Dechirp:          z(t) = s(t) .* conj(r(t))\n');
fprintf(fid, 'Beat frequency:   f_b  = S * delta\n');
fprintf(fid, '\n');
fprintf(fid, 'Clock model:\n');
fprintf(fid, '  T_A(t) = t\n');
fprintf(fid, '  T_B(t) = t + theta    (positive theta => B ahead of A)\n');
fprintf(fid, '\n');
fprintf(fid, 'Effective delays:\n');
fprintf(fid, '  delta_AB = tau + theta\n');
fprintf(fid, '  delta_BA = tau - theta\n');
fprintf(fid, '\n');
fprintf(fid, 'Recovery:\n');
fprintf(fid, '  tau_hat   = (f_AB + f_BA) / (2*S)\n');
fprintf(fid, '  theta_hat = (f_AB - f_BA) / (2*S)\n');
fprintf(fid, '```\n\n');

fprintf(fid, '## 7. Figures\n\n');
fprintf(fid, '- `figures/fig01_v0_single_link.png` -- V0 delay-to-frequency conversion\n');
fprintf(fid, '- `figures/fig02_v1_two_way.png` -- V1 two-way timing summary\n');
fprintf(fid, '- `figures/fig03_delay_linearity.png` -- Delay linearity sweep\n');
fprintf(fid, '- `figures/fig04_theta_recovery.png` -- Clock-offset recovery sweep\n\n');

fprintf(fid, '## 8. Next Steps\n\n');
fprintf(fid, '1. **V2 -- AWGN:** Add noise to quantify estimator precision vs SNR.\n');
fprintf(fid, '2. **V3 -- Independent oscillator effects:** Carrier-frequency offset,\n');
fprintf(fid, '   clock skew, slope mismatch.\n');
fprintf(fid, '3. **Estimator comparison:** FFT, phase-slope, CZT under noise.\n');
fprintf(fid, '4. **AWR2944 parameter mapping:** Map hardware chirp profile to simulation config.\n');
fprintf(fid, '5. **Hardware characterization:** Second AWR2944 board for two-way measurements.\n\n');

fprintf(fid, '## 9. Disclaimer\n\n');
fprintf(fid, '> **These results are from an IDEAL, NOISE-FREE simulation.** They demonstrate\n');
fprintf(fid, '> mathematical correctness of the FMCW timing model, NOT achievable hardware\n');
fprintf(fid, '> performance. 10-ps accuracy on real AWR2944 hardware has NOT been demonstrated\n');
fprintf(fid, '> and requires additional modeling and measurement.\n');

fclose(fid);
fprintf('  Saved: results/saeed_morning_summary.md\n');
