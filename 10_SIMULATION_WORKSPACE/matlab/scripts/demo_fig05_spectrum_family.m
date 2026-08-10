% demo_fig05_spectrum_family.m
% Figure 5: Delay-dependent beat-spectrum family.
%
% Shows how the FMCW beat spectrum shifts with one-way delay at fixed slope.
% Each trace is a separate ideal observation (not simultaneous targets).
%
% Uses the validated simulate_ideal_link() machinery for every trace.

%% Setup
cfg = make_default_params();
sty = fig_style();
S   = cfg.S;
Fs  = cfg.Fs;
N   = cfg.N;

script_dir = fileparts(mfilename('fullpath'));
fig_dir    = fullfile(script_dir, '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% Delay set
delays_ns = [1, 2.5, 5, 10, 20];
delays    = delays_ns * 1e-9;
n_traces  = length(delays);

% Theoretical beat frequencies
fb_theory = S * delays;
fprintf('\n  Figure 5 -- Delay-dependent spectrum family\n');
fprintf('  S = %.3f MHz/us\n', S/1e12);
for i = 1:n_traces
    fprintf('    delta = %5.1f ns  ->  f_b = %.3f kHz  (theory: S*delta = %.3f kHz)\n', ...
            delays_ns(i), fb_theory(i)/1e3, S*delays(i)/1e3);
end

%% Compute spectra
N_half   = floor(N/2);
df       = Fs / N;
freq_kHz = (0:N_half).' * df / 1e3;
spectra  = zeros(N_half+1, n_traces);
f_est    = zeros(1, n_traces);

for i = 1:n_traces
    link = simulate_ideal_link(cfg, delays(i));
    Z    = fft(link.beat);
    spectra(:,i) = abs(Z(1:N_half+1));
    est = estimate_beat_phase_slope(link.beat, Fs);
    f_est(i) = est.f_est;

    % Verify theory
    rel_err = abs(f_est(i) - fb_theory(i)) / fb_theory(i);
    assert(rel_err < 1e-10, ...
        sprintf('Fig5 check FAIL: delta=%.1f ns, rel_err=%.2e', delays_ns(i), rel_err));
end
fprintf('    All theory checks passed (rel_err < 1e-10)\n');

%% Normalize spectra (each to own peak)
for i = 1:n_traces
    spectra(:,i) = spectra(:,i) / max(spectra(:,i));
end

%% Plot: vertically offset stacked spectra
fig5 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

% Color gradient from blue to red across traces
colors = zeros(n_traces, 3);
for i = 1:n_traces
    frac = (i-1) / max(n_traces-1, 1);
    colors(i,:) = (1-frac) * sty.c_blue + frac * sty.c_red;
end

offset_step = 1.2;  % vertical offset between traces

for i = 1:n_traces
    y_offset = (n_traces - i) * offset_step;
    mag_norm = spectra(:,i);
    plot(freq_kHz, mag_norm + y_offset, '-', 'Color', colors(i,:), ...
         'LineWidth', sty.lw_data); hold on;

    % Theory marker (vertical dashed line segment)
    xth = fb_theory(i)/1e3;
    plot([xth xth], [y_offset y_offset + 1.05], '--', ...
         'Color', colors(i,:), 'LineWidth', sty.lw_theory);

    % Phase-slope marker
    plot(f_est(i)/1e3, y_offset + 1.0, '^', 'Color', colors(i,:), ...
         'MarkerSize', 4, 'MarkerFaceColor', colors(i,:));

    % Label
    text(750, y_offset + 0.5, ...
         sprintf('\\delta = %.1f ns  (f_b = %.1f kHz)', delays_ns(i), fb_theory(i)/1e3), ...
         'FontSize', sty.fs_annot, 'Color', colors(i,:), 'VerticalAlignment', 'middle');
end

xlabel('Frequency [kHz]'); ylabel('Normalized |Z(f)|  (stacked)');
title('Beat spectrum vs one-way delay  (fixed S)', 'FontSize', sty.fs_title);
xlim([0 900]);
set(gca, 'YTick', []);  % no y-ticks for stacked display
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.15);

text(0.02, 0.02, ...
     {'Each trace is a separate ideal observation.'; ...
      'These are not simultaneous targets.'}, ...
     'Units', 'normalized', 'FontSize', sty.fs_annot, ...
     'FontAngle', 'italic', 'Color', sty.c_gray, 'VerticalAlignment', 'bottom');

text(0.98, 0.02, ...
     sprintf('S = %.3f MHz/\\mus  |  Ideal noise-free model', S/1e12), ...
     'Units', 'normalized', 'HorizontalAlignment', 'right', ...
     'FontSize', sty.fs_annot, 'Color', sty.c_gray, 'VerticalAlignment', 'bottom');

save_fig(fig5, fullfile(fig_dir, 'fig05_delay_spectrum_family'));
close(fig5);
fprintf('  Saved: figures/fig05_delay_spectrum_family.png\n');
