% demo_v2a_cfo.m
% V2a: Carrier-Frequency Offset demonstration with three-way comparison.
%
% Generates:
%   figures/fig07_cfo_bias_vs_offset      -- TWTT timing bias vs CFO
%   figures/fig08_cfo_calibration_tone     -- before/after tone correction
%   figures/fig09_cfo_updown_comparison    -- up/down vs cal-tone recovery
%
% Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section G.1

%% Setup
cfg = make_default_params();
sty = fig_style();
S   = cfg.S;
Fs  = cfg.Fs;
N   = cfg.N;
t   = (0:N-1).' / Fs;
Tobs = N / Fs;

tau   = 5e-9;
theta = 100e-12;

%% Output directory
script_dir = fileparts(mfilename('fullpath'));
fig_dir    = fullfile(script_dir, '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% Print headline summary
fprintf('\n');
fprintf('====================================================\n');
fprintf('  FMCW V2a -- CARRIER-FREQUENCY OFFSET RESULT\n');
fprintf('====================================================\n');
fprintf('  Slope S:               %.3f MHz/us\n',     S / 1e12);
fprintf('  tau (propagation):     %.3f ns\n',          tau * 1e9);
fprintf('  theta (clock offset):  %.1f ps\n',          theta * 1e12);

% Three-way comparison at Df = 100 kHz
Df_demo = 100e3;
fprintf('  Delta_f (CFO):         %.1f kHz\n',         Df_demo / 1e3);
fprintf('  ----\n');

% Method A: Naive (no correction)
res = simulate_cfo_link(cfg, tau, theta, Df_demo);
f_AB = estimate_beat_phase_slope(res.beat_AB, Fs).f_est;
f_BA = estimate_beat_phase_slope(res.beat_BA, Fs).f_est;
[tau_A, theta_A] = solve_twtt(f_AB, f_BA, S);
fprintf('  Method A (naive):\n');
fprintf('    tau_hat   = %.9f ns  (error: %.2e s)\n', tau_A*1e9, abs(tau_A - tau));
fprintf('    theta_hat = %.4f ps   (bias: %.4f ps = Df/S)\n', ...
        theta_A*1e12, (theta_A - theta)*1e12);

% Method B: Calibration tone correction
z_cal = generate_cal_tone(t, Df_demo);
Df_hat = estimate_cfo_from_tone(z_cal, Fs);
beat_AB_corr = correct_cfo(res.beat_AB, t, Df_hat, 'AB');
beat_BA_corr = correct_cfo(res.beat_BA, t, Df_hat, 'BA');
f_AB_corr = estimate_beat_phase_slope(beat_AB_corr, Fs).f_est;
f_BA_corr = estimate_beat_phase_slope(beat_BA_corr, Fs).f_est;
[tau_B, theta_B] = solve_twtt(f_AB_corr, f_BA_corr, S);
fprintf('  Method B (cal-tone corrected):\n');
fprintf('    Df_hat    = %.1f kHz\n', Df_hat / 1e3);
fprintf('    tau_hat   = %.9f ns  (error: %.2e s)  (floating-point closure)\n', ...
        tau_B*1e9, abs(tau_B - tau));
fprintf('    theta_hat = %.4f ps   (error: %.2e s)  (floating-point closure)\n', ...
        theta_B*1e12, abs(theta_B - theta));

% Method C: Up/down chirp
delta_AB = tau + theta;
link_up = simulate_ideal_link(cfg, delta_AB);
beat_up = apply_cfo(link_up.beat, t, Df_demo, 'AB');
f_up = estimate_beat_phase_slope(beat_up, Fs).f_est;

cfg_down = cfg;
cfg_down.S = -S;
link_down = simulate_ideal_link(cfg_down, delta_AB);
beat_down = apply_cfo(link_down.beat, t, Df_demo, 'AB');
f_down = estimate_beat_phase_slope(beat_down, Fs).f_est;

[Df_C, delta_C] = solve_twtt_updown(f_up, f_down, S);
fprintf('  Method C (up/down chirp):\n');
fprintf('    Df_hat    = %.1f kHz\n', Df_C / 1e3);
fprintf('    delta_hat = %.9f ns  (error: %.2e s)  (floating-point closure)\n', ...
        delta_C*1e9, abs(delta_C - delta_AB));
fprintf('  ----\n');
fprintf('  NOTE: All results are from the ideal noise-free model.\n');
fprintf('  Sub-femtosecond residuals are floating-point closure,\n');
fprintf('  not physical timing precision.\n');
fprintf('====================================================\n\n');

%% ========== Figure 7: TWTT Bias vs Injected CFO ==========
% Sweep CFO from 10 Hz to 2 MHz (stay within Nyquist)
Df_sweep = logspace(1, log10(2e6), 40);
bias_naive  = zeros(size(Df_sweep));
bias_corr   = zeros(size(Df_sweep));
bias_theory = zeros(size(Df_sweep));

for k = 1:length(Df_sweep)
    Df_k = Df_sweep(k);

    % Naive
    res_k = simulate_cfo_link(cfg, tau, theta, Df_k);
    fAB_k = estimate_beat_phase_slope(res_k.beat_AB, Fs).f_est;
    fBA_k = estimate_beat_phase_slope(res_k.beat_BA, Fs).f_est;
    [~, theta_naive_k] = solve_twtt(fAB_k, fBA_k, S);
    bias_naive(k) = abs(theta_naive_k - theta);

    % Cal-tone corrected
    z_cal_k = generate_cal_tone(t, Df_k);
    Df_hat_k = estimate_cfo_from_tone(z_cal_k, Fs);
    beat_AB_k = correct_cfo(res_k.beat_AB, t, Df_hat_k, 'AB');
    beat_BA_k = correct_cfo(res_k.beat_BA, t, Df_hat_k, 'BA');
    fAB_ck = estimate_beat_phase_slope(beat_AB_k, Fs).f_est;
    fBA_ck = estimate_beat_phase_slope(beat_BA_k, Fs).f_est;
    [~, theta_corr_k] = solve_twtt(fAB_ck, fBA_ck, S);
    bias_corr(k) = abs(theta_corr_k - theta);

    % Theory
    bias_theory(k) = Df_k / S;
end

fig7 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

loglog(Df_sweep/1e3, bias_naive*1e12, '-', ...
       'Color', sty.c_red, 'LineWidth', sty.lw_data); hold on;
loglog(Df_sweep/1e3, bias_theory*1e12, '--', ...
       'Color', sty.c_black, 'LineWidth', sty.lw_theory);
loglog(Df_sweep/1e3, max(bias_corr*1e12, 1e-12), 'o', ...
       'Color', sty.c_green, 'MarkerSize', 3, 'LineWidth', 1.0);

xlabel('\Delta f  [kHz]', 'FontSize', sty.fs_axis);
ylabel('|\theta_{hat} - \theta|  [ps]', 'FontSize', sty.fs_axis);
title('V2a:  Clock-Offset Bias vs. Carrier-Frequency Offset', 'FontSize', sty.fs_title);
lg = legend('Naive V1 solver (biased)', ...
            'Theory: \Delta f / S', ...
            'After cal-tone correction', ...
            'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);

% Reference lines
yline(10, ':', 'Color', sty.c_gray, 'LineWidth', 0.8);
text(Df_sweep(end)/1e3 * 0.7, 12, '10 ps target', ...
     'FontSize', sty.fs_annot, 'Color', sty.c_gray, ...
     'HorizontalAlignment', 'right');

set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

try
    sgtitle('Ideal noise-free model', 'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.25 0.94 0.5 0.05], ...
               'String', 'Ideal noise-free model', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig7, fullfile(fig_dir, 'fig07_cfo_bias_vs_offset'));
close(fig7);
fprintf('  Saved: figures/fig07_cfo_bias_vs_offset.png\n');

%% ========== Figure 8: Before/After Calibration Tone ==========
fig8 = figure('Position', sty.fig_tall, 'Color', 'w', 'Visible', 'off');

Df_fig8 = 100e3;
res8 = simulate_cfo_link(cfg, tau, theta, Df_fig8);

% Panel (a): Beat spectra with CFO
subplot(3,1,1);
fft_AB = estimate_beat_fft(res8.beat_AB, Fs);
fft_BA = estimate_beat_fft(res8.beat_BA, Fs);
N_half = floor(N/2);
freq_kHz = fft_AB.freq_axis(1:N_half+1) / 1e3;
mag_AB_dB = 20*log10(fft_AB.spectrum_mag(1:N_half+1) / max(fft_AB.spectrum_mag) + 1e-30);
mag_BA_dB = 20*log10(fft_BA.spectrum_mag(1:N_half+1) / max(fft_BA.spectrum_mag) + 1e-30);

plot(freq_kHz, mag_AB_dB, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;
plot(freq_kHz, mag_BA_dB, '-', 'Color', sty.c_red, 'LineWidth', sty.lw_data);
xline(res8.f_AB_theory/1e3, '--', 'Color', sty.c_blue, 'LineWidth', 0.6);
xline(res8.f_BA_theory/1e3, '--', 'Color', sty.c_red, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title(sprintf('(a)  Beat spectra with CFO = %.0f kHz', Df_fig8/1e3), 'FontSize', sty.fs_title);
lg = legend(sprintf('A\\rightarrowB: %.1f kHz', res8.f_AB_theory/1e3), ...
            sprintf('B\\rightarrowA: %.1f kHz', res8.f_BA_theory/1e3), ...
            'Location', 'northeast');
set(lg, 'FontSize', sty.fs_legend);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Panel (b): Calibration tone spectrum
subplot(3,1,2);
z_cal8 = generate_cal_tone(t, Df_fig8);
fft_cal = estimate_beat_fft(z_cal8, Fs);
mag_cal_dB = 20*log10(fft_cal.spectrum_mag(1:N_half+1) / max(fft_cal.spectrum_mag) + 1e-30);

plot(freq_kHz, mag_cal_dB, '-', 'Color', [0.60 0.20 0.80], 'LineWidth', sty.lw_data); hold on;
xline(Df_fig8/1e3, '--', 'Color', sty.c_black, 'LineWidth', sty.lw_theory);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title(sprintf('(b)  Calibration tone: peak at \\Delta f = %.0f kHz', Df_fig8/1e3), ...
      'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Panel (c): Corrected beat spectra
subplot(3,1,3);
Df_hat8 = estimate_cfo_from_tone(z_cal8, Fs);
beat_AB8 = correct_cfo(res8.beat_AB, t, Df_hat8, 'AB');
beat_BA8 = correct_cfo(res8.beat_BA, t, Df_hat8, 'BA');
fft_AB8 = estimate_beat_fft(beat_AB8, Fs);
fft_BA8 = estimate_beat_fft(beat_BA8, Fs);
mag_AB8_dB = 20*log10(fft_AB8.spectrum_mag(1:N_half+1) / max(fft_AB8.spectrum_mag) + 1e-30);
mag_BA8_dB = 20*log10(fft_BA8.spectrum_mag(1:N_half+1) / max(fft_BA8.spectrum_mag) + 1e-30);

f_AB_corr8 = estimate_beat_phase_slope(beat_AB8, Fs).f_est;
f_BA_corr8 = estimate_beat_phase_slope(beat_BA8, Fs).f_est;

plot(freq_kHz, mag_AB8_dB, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;
plot(freq_kHz, mag_BA8_dB, '-', 'Color', sty.c_red, 'LineWidth', sty.lw_data);
xline(f_AB_corr8/1e3, '--', 'Color', sty.c_blue, 'LineWidth', 0.6);
xline(f_BA_corr8/1e3, '--', 'Color', sty.c_red, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(c)  After calibration-tone correction', 'FontSize', sty.fs_title);
lg = legend(sprintf('A\\rightarrowB: %.1f kHz', f_AB_corr8/1e3), ...
            sprintf('B\\rightarrowA: %.1f kHz', f_BA_corr8/1e3), ...
            'Location', 'northeast');
set(lg, 'FontSize', sty.fs_legend);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

try
    sgtitle('Ideal noise-free model', 'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.25 0.94 0.5 0.05], ...
               'String', 'Ideal noise-free model', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig8, fullfile(fig_dir, 'fig08_cfo_calibration_tone'));
close(fig8);
fprintf('  Saved: figures/fig08_cfo_calibration_tone.png\n');

%% ========== Figure 9: Up/Down vs Cal-Tone Recovery ==========
fig9 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

% Sweep CFO, compare cal-tone and up/down recovery
Df_sweep9 = logspace(1, log10(2e6), 30);
Df_tone_hat = zeros(size(Df_sweep9));
Df_updn_hat = zeros(size(Df_sweep9));

for k = 1:length(Df_sweep9)
    Df_k = Df_sweep9(k);

    % Cal tone recovery
    z_cal_k = generate_cal_tone(t, Df_k);
    Df_tone_hat(k) = estimate_cfo_from_tone(z_cal_k, Fs);

    % Up/down recovery
    lnk_up = simulate_ideal_link(cfg, delta_AB);
    beat_up_k = apply_cfo(lnk_up.beat, t, Df_k, 'AB');
    f_up_k = estimate_beat_phase_slope(beat_up_k, Fs).f_est;

    lnk_dn = simulate_ideal_link(cfg_down, delta_AB);
    beat_dn_k = apply_cfo(lnk_dn.beat, t, Df_k, 'AB');
    f_dn_k = estimate_beat_phase_slope(beat_dn_k, Fs).f_est;

    [Df_updn_hat(k), ~] = solve_twtt_updown(f_up_k, f_dn_k, S);
end

subplot(2,1,1);
loglog(Df_sweep9/1e3, Df_sweep9/1e3, '-', 'Color', sty.c_black, 'LineWidth', sty.lw_theory); hold on;
loglog(Df_sweep9/1e3, Df_tone_hat/1e3, 'o', 'Color', sty.c_green, 'MarkerSize', 4);
loglog(Df_sweep9/1e3, Df_updn_hat/1e3, 'x', 'Color', sty.c_blue, 'MarkerSize', 5);
xlabel('Injected \Delta f  [kHz]'); ylabel('Recovered \Delta f  [kHz]');
title('(a)  CFO Recovery: cal-tone vs up/down chirp', 'FontSize', sty.fs_title);
lg = legend('Identity', 'Cal tone', 'Up/down chirp', 'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

subplot(2,1,2);
err_tone = abs(Df_tone_hat - Df_sweep9);
err_updn = abs(Df_updn_hat - Df_sweep9);
loglog(Df_sweep9/1e3, err_tone + 1e-20, 'o-', 'Color', sty.c_green, ...
       'MarkerSize', 3, 'LineWidth', 1.0); hold on;
loglog(Df_sweep9/1e3, err_updn + 1e-20, 'x-', 'Color', sty.c_blue, ...
       'MarkerSize', 3, 'LineWidth', 1.0);
xlabel('Injected \Delta f  [kHz]');
ylabel('|\Delta f_{hat} - \Delta f|  [Hz]');
title('(b)  CFO recovery error', 'FontSize', sty.fs_title);
lg = legend('Cal tone', 'Up/down chirp', 'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

text(0.98, 0.10, 'Floating-point scale; not physical precision', ...
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

save_fig(fig9, fullfile(fig_dir, 'fig09_cfo_updown_comparison'));
close(fig9);
fprintf('  Saved: figures/fig09_cfo_updown_comparison.png\n');
