% demo_fig06_slope_sensitivity.m
% Figure 6: Timing sensitivity vs chirp slope.
%
% Shows how the measurable directional beat-frequency signature scales
% linearly with chirp slope S for fixed tau and theta.
%
% The slope sweep is ILLUSTRATIVE. Hardware chirp constraints have not
% been imposed.

%% Setup
cfg = make_default_params();
sty = fig_style();
Fs  = cfg.Fs;
N   = cfg.N;

script_dir = fileparts(mfilename('fullpath'));
fig_dir    = fullfile(script_dir, '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% Fixed timing parameters
tau   = 5e-9;       % 5 ns propagation delay
theta = 100e-12;    % 100 ps relative clock epoch offset

%% Illustrative slope sweep
S_MHz_per_us = [10, 20, 29.982, 40, 60];
S_values     = S_MHz_per_us * 1e12;    % convert to Hz/s
n_slopes     = length(S_values);

%% Compute
f_AB     = zeros(1, n_slopes);
f_BA     = zeros(1, n_slopes);
f_mid    = zeros(1, n_slopes);
delta_f  = zeros(1, n_slopes);

fprintf('\n  Figure 6 -- Timing sensitivity vs chirp slope\n');
fprintf('  tau = %.1f ns,  theta = %.1f ps\n', tau*1e9, theta*1e12);

for i = 1:n_slopes
    Si = S_values(i);

    % Run through validated signal chain
    cfg_i   = cfg;
    cfg_i.S = Si;

    link_AB = simulate_ideal_link(cfg_i, tau + theta);
    link_BA = simulate_ideal_link(cfg_i, tau - theta);
    est_AB  = estimate_beat_phase_slope(link_AB.beat, Fs);
    est_BA  = estimate_beat_phase_slope(link_BA.beat, Fs);

    f_AB(i)    = est_AB.f_est;
    f_BA(i)    = est_BA.f_est;
    f_mid(i)   = Si * tau;
    delta_f(i) = f_AB(i) - f_BA(i);

    % Verify theory
    delta_f_theory = 2 * Si * theta;
    rel_err = abs(delta_f(i) - delta_f_theory) / delta_f_theory;
    assert(rel_err < 1e-10, ...
        sprintf('Fig6 check FAIL: S=%.0f MHz/us, rel_err=%.2e', S_MHz_per_us(i), rel_err));

    fprintf('    S = %6.3f MHz/us  ->  Delta_f = %.3f kHz  (theory: 2S*theta = %.3f kHz)\n', ...
            S_MHz_per_us(i), delta_f(i)/1e3, delta_f_theory/1e3);
end
fprintf('    All theory checks passed (rel_err < 1e-10)\n');

%% Plot
fig6 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

% --- Panel (a): Directional offsets relative to midpoint ---
subplot(2,1,1);
f_AB_offset = (f_AB - f_mid) / 1e3;  % kHz
f_BA_offset = (f_BA - f_mid) / 1e3;  % kHz

plot(S_MHz_per_us, f_AB_offset, 'o-', 'Color', sty.c_blue, ...
     'LineWidth', sty.lw_data, 'MarkerSize', sty.ms_data, ...
     'MarkerFaceColor', sty.c_blue); hold on;
plot(S_MHz_per_us, f_BA_offset, 's-', 'Color', sty.c_red, ...
     'LineWidth', sty.lw_data, 'MarkerSize', sty.ms_data, ...
     'MarkerFaceColor', sty.c_red);
yline(0, '-', 'Color', sty.c_ltgray, 'LineWidth', 0.8);

xlabel('Chirp slope S [MHz/\mus]');
ylabel('f - S\tau  [kHz]');
title(sprintf('(a)  Directional beat offsets relative to S\\tau   (\\theta = %.0f ps)', ...
      theta*1e12), 'FontSize', sty.fs_title);
lg = legend('f_{AB} - S\tau  = +S\theta', 'f_{BA} - S\tau  = -S\theta', ...
            'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% --- Panel (b): Total directional separation ---
subplot(2,1,2);
delta_f_kHz = delta_f / 1e3;
delta_f_theory_kHz = 2 * S_values * theta / 1e3;

plot(S_MHz_per_us, delta_f_kHz, 'o-', 'Color', sty.c_blue, ...
     'LineWidth', sty.lw_data, 'MarkerSize', sty.ms_data, ...
     'MarkerFaceColor', sty.c_blue); hold on;
plot(S_MHz_per_us, delta_f_theory_kHz, '--', 'Color', sty.c_black, ...
     'LineWidth', sty.lw_theory);

% Mark the nominal operating point
idx_nom = find(abs(S_MHz_per_us - 29.982) < 0.01, 1);
if ~isempty(idx_nom)
    plot(S_MHz_per_us(idx_nom), delta_f_kHz(idx_nom), 'o', ...
         'Color', sty.c_green, 'MarkerSize', sty.ms_accent + 2, ...
         'LineWidth', 1.5);
end

xlabel('Chirp slope S [MHz/\mus]');
ylabel('\Deltaf_{TWTT}  [kHz]');
title(sprintf('(b)  Timing sensitivity:  \\Deltaf_{TWTT} = 2S\\theta   (\\tau = %.0f ns,  \\theta = %.0f ps)', ...
      tau*1e9, theta*1e12), 'FontSize', sty.fs_title);
lg = legend('Simulated  \Deltaf = f_{AB} - f_{BA}', ...
            'Theory:  2S\theta', ...
            'Nominal S = 29.982 MHz/\mus', ...
            'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Annotation
text(0.98, 0.05, ...
     {'Illustrative slope sensitivity study'; ...
      'Hardware chirp constraints not yet imposed'}, ...
     'Units', 'normalized', 'HorizontalAlignment', 'right', ...
     'FontSize', sty.fs_annot, 'FontAngle', 'italic', 'Color', sty.c_gray, ...
     'VerticalAlignment', 'bottom');

try
    sgtitle('Ideal noise-free model', 'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.25 0.94 0.5 0.05], ...
               'String', 'Ideal noise-free model', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig6, fullfile(fig_dir, 'fig06_slope_timing_sensitivity'));
close(fig6);
fprintf('  Saved: figures/fig06_slope_timing_sensitivity.png\n');
