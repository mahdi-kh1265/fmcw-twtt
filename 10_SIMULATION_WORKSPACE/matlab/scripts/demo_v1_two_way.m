% demo_v1_two_way.m
% V1: Ideal reciprocal two-way FMCW timing demonstration.
%
% Generates:
%   figures/fig02_v1_two_way     -- TWTT summary
%   figures/fig04_theta_recovery -- clock-offset recovery sweep
%   results/saeed_morning_summary.md -- PM-facing report
%
% Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections C, D, G, H

%% Setup
cfg   = make_default_params();
sty   = fig_style();
S     = cfg.S;
Fs    = cfg.Fs;
N     = cfg.N;
Tobs  = N / Fs;
tau   = 5e-9;       % 5 ns propagation delay
theta = 100e-12;    % 100 ps clock epoch offset

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
fprintf('  Injected clock epoch offset: %.1f ps\n',          theta * 1e12);
fprintf('  ----\n');
fprintf('  Phase-slope estimates (separate directional observations):\n');
fprintf('    A->B phase-slope:          %.1f Hz\n',          phase_AB.f_est);
fprintf('    B->A phase-slope:          %.1f Hz\n',          phase_BA.f_est);
fprintf('  Raw FFT nearest-bin estimates (separate directional observations):\n');
fprintf('    A->B FFT peak:             %.1f Hz\n',          fft_AB.f_peak);
fprintf('    B->A FFT peak:             %.1f Hz\n',          fft_BA.f_peak);
fprintf('    NOTE: Both map to the same DFT bin (bin spacing %.1f Hz)\n', fft_AB.df);
fprintf('  Theoretical beat frequencies:\n');
fprintf('    f_AB theory:               %.1f Hz\n',          link_AB.fb_theory);
fprintf('    f_BA theory:               %.1f Hz\n',          link_BA.fb_theory);
fprintf('    f_AB - f_BA (theory):      %.1f Hz\n',          link_AB.fb_theory - link_BA.fb_theory);
fprintf('  ----\n');
fprintf('  Recovered propagation delay: %.9f ns\n',          tau_hat * 1e9);
fprintf('  Propagation-delay error:     %.2e s  (floating-point closure)\n', abs(tau_hat - tau));
fprintf('  Recovered clock epoch offset:%.3f ps\n',          theta_hat * 1e12);
fprintf('  Clock-offset error:          %.2e s  (floating-point closure)\n', abs(theta_hat - theta));
fprintf('  ----\n');
fprintf('  MODEL: Ideal analytic complex-baseband FMCW truth model\n');
fprintf('  CONDITIONS: IDEAL, noise-free, matched oscillators\n');
fprintf('====================================================\n\n');

%% Output directories
script_dir  = fileparts(mfilename('fullpath'));
fig_dir     = fullfile(script_dir, '..', 'figures');
results_dir = fullfile(script_dir, '..', 'results');
if ~exist(fig_dir, 'dir'),     mkdir(fig_dir);     end
if ~exist(results_dir, 'dir'), mkdir(results_dir); end

%% ========== Figure 2: Two-Way FMCW / TWTT Summary ==========
fig2 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

N_half   = floor(N/2);
freq_kHz = fft_AB.freq_axis(1:N_half+1) / 1e3;
mag_AB   = 20*log10(fft_AB.spectrum_mag(1:N_half+1) / ...
           max(fft_AB.spectrum_mag) + 1e-30);
mag_BA   = 20*log10(fft_BA.spectrum_mag(1:N_half+1) / ...
           max(fft_BA.spectrum_mag) + 1e-30);

% --- Panel (a): Directional spectra (zoomed) ---
subplot(1,2,1);

plot(freq_kHz, mag_AB, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;
plot(freq_kHz, mag_BA, '-', 'Color', sty.c_red,  'LineWidth', sty.lw_data);

% Theory markers
xline(link_AB.fb_theory/1e3, '--', 'Color', sty.c_blue, 'LineWidth', sty.lw_theory);
xline(link_BA.fb_theory/1e3, '--', 'Color', sty.c_red,  'LineWidth', sty.lw_theory);

% FFT nearest-bin (same for both)
plot(fft_AB.f_peak/1e3, 0, 'v', 'Color', sty.c_gray, ...
     'MarkerSize', sty.ms_accent, 'MarkerFaceColor', sty.c_gray);

% Phase-slope markers
plot(phase_AB.f_est/1e3, 0, '^', 'Color', sty.c_blue, ...
     'MarkerSize', sty.ms_data, 'MarkerFaceColor', sty.c_blue);
plot(phase_BA.f_est/1e3, 0, '^', 'Color', sty.c_red, ...
     'MarkerSize', sty.ms_data, 'MarkerFaceColor', sty.c_red);

xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(a)  Directional beat spectra', 'FontSize', sty.fs_title);
lg = legend(sprintf('A{\\rightarrow}B  (f_{AB}=%.1f kHz)', phase_AB.f_est/1e3), ...
       sprintf('B{\\rightarrow}A  (f_{BA}=%.1f kHz)', phase_BA.f_est/1e3), ...
       sprintf('f_{AB} theory'), ...
       sprintf('f_{BA} theory'), ...
       sprintf('FFT bin: %.1f kHz', fft_AB.f_peak/1e3), ...
       'Location', 'northeast');
set(lg, 'FontSize', sty.fs_legend);
xlim([50 350]);  % zoom around the beat region
ylim([-50 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% --- Panel (b): Recovery summary ---
subplot(1,2,2);
axis off;
lines = {
    '\bf{Two-Way Recovery}', ...
    '', ...
    '{\tau}_{hat} = (f_{AB} + f_{BA}) / (2S)', ...
    '{\theta}_{hat} = (f_{AB} - f_{BA}) / (2S)', ...
    '', ...
    sprintf('Injected \\tau :        %.3f ns', tau*1e9), ...
    sprintf('Injected \\theta :      %.1f ps', theta*1e12), ...
    '   (relative clock epoch offset)', ...
    '', ...
    sprintf('f_{AB} (phase-slope):  %.1f Hz', phase_AB.f_est), ...
    sprintf('f_{BA} (phase-slope):  %.1f Hz', phase_BA.f_est), ...
    sprintf('f_{AB} - f_{BA} :      %.1f Hz', phase_AB.f_est - phase_BA.f_est), ...
    '', ...
    sprintf('Recovered \\tau :       %.3f ns', tau_hat*1e9), ...
    sprintf('Recovered \\theta :     %.1f ps', theta_hat*1e12), ...
    '', ...
    sprintf('FFT bin spacing:       %.1f kHz', fft_AB.df/1e3), ...
    'Both records -> same FFT bin', ...
    '', ...
    '\it{Ideal noise-free model}', ...
    '\it{Separate directional observations}'
};
text(0.05, 0.95, lines, 'Units', 'normalized', ...
     'VerticalAlignment', 'top', 'FontSize', sty.fs_annot + 0.5, ...
     'FontName', 'FixedWidth', 'Interpreter', 'tex');

fig2_title = sprintf('V1 TWTT:  \\tau = %.1f ns,  \\theta = %.0f ps,  S = %.3f MHz/\\mus', ...
        tau*1e9, theta*1e12, S/1e12);
try
    sgtitle(fig2_title, 'FontSize', sty.fs_title, 'FontWeight', 'bold');
catch
    annotation('textbox', [0.1 0.93 0.8 0.06], 'String', ...
               sprintf('V1 TWTT:  tau = %.1f ns,  theta = %.0f ps,  S = %.3f MHz/us', ...
               tau*1e9, theta*1e12, S/1e12), ...
               'FontSize', sty.fs_title, 'FontWeight', 'bold', ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig2, fullfile(fig_dir, 'fig02_v1_two_way'));
close(fig2);
fprintf('  Saved: figures/fig02_v1_two_way.png\n');

%% ========== Figure 4: Clock Epoch Offset Recovery Sweep ==========
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

fig4 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

subplot(2,1,1);
plot(theta_vals*1e12, theta_recovered*1e12, 'o', 'Color', sty.c_blue, ...
     'MarkerSize', sty.ms_data); hold on;
plot(theta_vals*1e12, theta_vals*1e12, '--', 'Color', sty.c_black, ...
     'LineWidth', sty.lw_theory);
xlabel('Injected \theta [ps]');
ylabel('Recovered \theta_{hat} [ps]');
title(sprintf('(a)  Relative clock epoch offset recovery  (\\tau = %.1f ns)', tau*1e9), ...
      'FontSize', sty.fs_title);
lg = legend('Recovered', 'Identity', 'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

subplot(2,1,2);
residual_ps = (theta_recovered - theta_vals) * 1e12;
plot(theta_vals*1e12, residual_ps, 'o-', 'Color', sty.c_black, ...
     'MarkerSize', 4, 'LineWidth', 1.0); hold on;
yline(0, '-', 'Color', sty.c_ltgray, 'LineWidth', 0.8);
xlabel('Injected \theta [ps]');
ylabel('\theta_{hat} - \theta [ps]');
title('(b)  Ideal-model numerical closure', 'FontSize', sty.fs_title);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

text(0.98, 0.05, 'Floating-point scale; not physical timing precision', ...
     'Units', 'normalized', 'HorizontalAlignment', 'right', ...
     'FontSize', sty.fs_annot, 'FontAngle', 'italic', 'Color', sty.c_gray);

try
    sgtitle('Ideal noise-free model', 'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.25 0.94 0.5 0.05], ...
               'String', 'Ideal noise-free model', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig4, fullfile(fig_dir, 'fig04_theta_recovery'));
close(fig4);
fprintf('  Saved: figures/fig04_theta_recovery.png\n');

%% ========== Morning Summary ==========
summary_path = fullfile(results_dir, 'saeed_morning_summary.md');
fid = fopen(summary_path, 'w');

fprintf(fid, '# FMCW Two-Way Time Transfer -- V0/V1 Simulation Results\n\n');
fprintf(fid, '**Date:** %s\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '**Model:** Ideal analytic complex-baseband FMCW truth model\n');
fprintf(fid, '**Status:** IDEAL / NOISE-FREE simulation only\n\n');
fprintf(fid, '---\n\n');

fprintf(fid, '## 1. Objective\n\n');
fprintf(fid, 'Demonstrate that FMCW dechirping converts sub-nanosecond propagation delay\n');
fprintf(fid, 'and picosecond relative clock epoch offset into easily estimated low-frequency\n');
fprintf(fid, 'beats, and that two-way sum/difference algebra recovers both quantities exactly\n');
fprintf(fid, 'under ideal conditions.\n\n');

fprintf(fid, '## 2. V0 Single-Link Result\n\n');
fprintf(fid, '| Quantity | Value |\n');
fprintf(fid, '|---|---|\n');
delta_v0 = 5e-9;
fprintf(fid, '| Injected delay | %.3f ns |\n', delta_v0 * 1e9);
v0link = simulate_ideal_link(cfg, delta_v0);
v0est  = estimate_beat_phase_slope(v0link.beat, Fs);
v0fft  = estimate_beat_fft(v0link.beat, Fs);
v0dhat = v0est.f_est / S;
fprintf(fid, '| Theoretical f_b | %.1f Hz |\n', v0link.fb_theory);
fprintf(fid, '| Phase-slope estimate | %.1f Hz |\n', v0est.f_est);
fprintf(fid, '| FFT nearest-bin estimate | %.1f Hz |\n', v0fft.f_peak);
fprintf(fid, '| Recovered delay | %.9f ns |\n', v0dhat * 1e9);
fprintf(fid, '| Delay error | %.1e s (floating-point closure, not physical precision) |\n\n', abs(v0dhat - delta_v0));

fprintf(fid, '## 3. V1 Two-Way Result\n\n');
fprintf(fid, 'In V1, "theta" denotes the **relative clock epoch offset** between stations.\n');
fprintf(fid, 'It does not model oscillator rate/frequency offset or clock skew.\n\n');
fprintf(fid, 'The A->B and B->A beat frequencies are obtained from **two separate directional\n');
fprintf(fid, 'dechirp observations**, not by resolving two simultaneous tones in a single\n');
fprintf(fid, 'spectrum.\n\n');
fprintf(fid, '| Quantity | Value |\n');
fprintf(fid, '|---|---|\n');
fprintf(fid, '| Injected tau | %.3f ns |\n', tau * 1e9);
fprintf(fid, '| Injected theta (clock epoch offset) | %.1f ps |\n', theta * 1e12);
fprintf(fid, '| Phase-slope f_AB | %.1f Hz |\n', phase_AB.f_est);
fprintf(fid, '| Phase-slope f_BA | %.1f Hz |\n', phase_BA.f_est);
fprintf(fid, '| FFT nearest-bin f_AB | %.1f Hz |\n', fft_AB.f_peak);
fprintf(fid, '| FFT nearest-bin f_BA | %.1f Hz |\n', fft_BA.f_peak);
fprintf(fid, '| f_AB - f_BA | %.1f Hz |\n', phase_AB.f_est - phase_BA.f_est);
fprintf(fid, '| Recovered tau | %.9f ns |\n', tau_hat * 1e9);
fprintf(fid, '| Recovered theta | %.3f ps |\n', theta_hat * 1e12);
fprintf(fid, '| tau error | %.1e s (floating-point closure, not physical precision) |\n', abs(tau_hat - tau));
fprintf(fid, '| theta error | %.1e s (floating-point closure, not physical precision) |\n\n', abs(theta_hat - theta));

fprintf(fid, '## 4. Model Assumptions and Intentionally Absent Effects\n\n');
fprintf(fid, 'V0/V1 is an **ideal analytic complex-baseband FMCW truth model**.\n');
fprintf(fid, 'It is not a full radar simulation, hardware digital twin, or realistic\n');
fprintf(fid, 'AWR2944 precision model.\n\n');
fprintf(fid, 'The following effects are **intentionally absent** from V0/V1:\n\n');
fprintf(fid, '- Receiver noise / SNR (no additive noise; infinite SNR)\n');
fprintf(fid, '- ADC quantization\n');
fprintf(fid, '- Independent carrier-frequency offset\n');
fprintf(fid, '- Clock-rate error / skew (theta is a constant epoch offset only)\n');
fprintf(fid, '- Phase noise\n');
fprintf(fid, '- Chirp nonlinearity\n');
fprintf(fid, '- Multipath\n');
fprintf(fid, '- Asymmetric hardware / group delay\n');
fprintf(fid, '- Calibration uncertainty\n');
fprintf(fid, '- Slope mismatch between stations\n');
fprintf(fid, '- Reciprocal propagation is assumed (same tau in both directions)\n');
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
fprintf(fid, 'Clock model (theta = relative clock epoch offset):\n');
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

fprintf(fid, '## 6a. FFT Resolution Note\n\n');
fprintf(fid, 'For the headline parameters (N=%d, Fs=%.0f MHz), the FFT bin spacing is\n', N, Fs/1e6);
fprintf(fid, '%.1f Hz. The nearest-bin FFT estimator maps both ideal directional records\n', fft_AB.df);
fprintf(fid, 'to the same raw DFT bin and therefore cannot recover the ~%.1f Hz directional\n', link_AB.fb_theory - link_BA.fb_theory);
fprintf(fid, 'beat-frequency difference.\n\n');
fprintf(fid, 'The phase-slope (LS) estimator operates on each separate complex record and\n');
fprintf(fid, 'recovers the underlying off-bin frequency exactly in this ideal noise-free model.\n\n');
fprintf(fid, 'Zero-padding interpolates the displayed spectrum; it does not increase physical\n');
fprintf(fid, 'observation time or add information.\n\n');

fprintf(fid, '## 7. Figures\n\n');
fprintf(fid, '### Primary / Saeed-facing\n\n');
fprintf(fid, '| Figure | Description |\n');
fprintf(fid, '|---|---|\n');
fprintf(fid, '| `fig01_v0_single_link` | FMCW delay -> beat conversion |\n');
fprintf(fid, '| `fig02_v1_two_way` | Two-way recovery of tau and theta |\n');
fprintf(fid, '| `fig06_slope_timing_sensitivity` | Ideal timing sensitivity vs chirp slope |\n\n');
fprintf(fid, '### Supporting / Validation\n\n');
fprintf(fid, '| Figure | Description |\n');
fprintf(fid, '|---|---|\n');
fprintf(fid, '| `fig03_delay_linearity` | Delay linearity sweep |\n');
fprintf(fid, '| `fig04_theta_recovery` | Theta recovery sweep |\n');
fprintf(fid, '| `fig05_delay_spectrum_family` | Delay-dependent spectrum family |\n\n');
fprintf(fid, 'The slope sweep in Figure 6 is **illustrative**; hardware chirp constraints\n');
fprintf(fid, 'have not yet been imposed.\n\n');

fprintf(fid, '## 8. Next Steps\n\n');
fprintf(fid, '1. **V2 -- AWGN:** Add noise to quantify estimator precision vs SNR.\n');
fprintf(fid, '2. **V3 -- Independent oscillator effects:** Carrier-frequency offset,\n');
fprintf(fid, '   clock skew, slope mismatch.\n');
fprintf(fid, '3. **Estimator comparison:** FFT, phase-slope, CZT under noise.\n');
fprintf(fid, '4. **AWR2944 parameter mapping:** Map hardware chirp profile to simulation config.\n');
fprintf(fid, '5. **Hardware characterization:** Second AWR2944 board for two-way measurements.\n\n');

fprintf(fid, '## 9. Disclaimer\n\n');
fprintf(fid, '> **These results are from an IDEAL, NOISE-FREE simulation.** They demonstrate\n');
fprintf(fid, '> mathematical correctness of the ideal analytic complex-baseband FMCW timing\n');
fprintf(fid, '> model, NOT achievable hardware performance. 10-ps accuracy on real AWR2944\n');
fprintf(fid, '> hardware has NOT been demonstrated and requires additional modeling and\n');
fprintf(fid, '> measurement. The sub-femtosecond error residuals reported above reflect\n');
fprintf(fid, '> IEEE 754 double-precision floating-point closure of the ideal deterministic\n');
fprintf(fid, '> model, not physical timing precision.\n');

fclose(fid);
fprintf('  Saved: results/saeed_morning_summary.md\n');
