function test_align_code_fractional()
% TEST_ALIGN_CODE_FRACTIONAL  Independent validation of align_code.
%
%   P16: Tests align_code with delta = 73.7 ns (not a round fraction
%   of T_chip or 1/Fs) against an independent hand-computed oracle.
%
%   The oracle computes expected chip state for each sample independently:
%     chip_idx(n) = floor( (t(n) - delta) / T_chip ) + 1, clamped to [1, L]
%     expected_code(n) = code(chip_idx(n))

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;
    N   = cfg.N;
    L   = 2;
    t   = (0:N-1).' / Fs;
    Tobs = N / Fs;
    T_chip = Tobs / L;

    delta = 73.7e-9;  % NOT round fraction of T_chip (12.8 us) or 1/Fs (100 ns)

    fprintf('  test_align_code_fractional ...\n');

    %% P16a: Code A (all +1) — trivial case, alignment doesn't matter
    code_A = generate_code('A', L);
    c_A = align_code(code_A, L, N, Fs, delta);
    assert(all(c_A == 1), 'P16a: all-ones code should be all +1 regardless of delta');
    fprintf('    P16a PASS: all-ones code unaffected by alignment\n');

    %% P16b: Code B [+1, -1] — verify each sample independently
    code_B = generate_code('B', L);
    c_B = align_code(code_B, L, N, Fs, delta);

    % Independent oracle: compute expected code state sample-by-sample
    c_expected = zeros(N, 1);
    for n = 1:N
        t_shifted = t(n) - delta;
        chip_idx = floor(t_shifted / T_chip) + 1;
        chip_idx = max(1, min(L, chip_idx));
        c_expected(n) = code_B(chip_idx);
    end

    mismatches = sum(c_B ~= c_expected);
    assert(mismatches == 0, ...
           'P16b: align_code mismatch at %d / %d samples for delta=73.7ns', mismatches, N);
    fprintf('    P16b PASS: 73.7 ns delay: all %d samples match independent oracle\n', N);

    %% P16c: Multiple fractional delays
    test_delays = [73.7e-9, 137.2e-9, 3.14e-9, 0, 50e-9, 99.9e-9, 200e-9];
    for k = 1:length(test_delays)
        d = test_delays(k);
        c_test = align_code(code_B, L, N, Fs, d);
        c_oracle = zeros(N, 1);
        for n = 1:N
            ts = t(n) - d;
            ci = floor(ts / T_chip) + 1;
            ci = max(1, min(L, ci));
            c_oracle(n) = code_B(ci);
        end
        assert(all(c_test == c_oracle), ...
               'P16c: mismatch at delta = %.1f ns', d*1e9);
    end
    fprintf('    P16c PASS: %d fractional delays all match oracle\n', length(test_delays));

    %% P16d: Verify transition point is correct for fractional delay
    % delta = 73.7 ns. T_chip = 12.8 us = N/(L*Fs) * 1e6 us.
    % The code transition (for shifted code) occurs at t = T_chip + delta.
    % T_chip = 12.8 us, delta = 73.7 ns, so transition at t = 12.800074 us.
    %
    % In MATLAB 1-based indexing: sample k has t = (k-1)/Fs.
    %   sample 129: t = 128/Fs = 12.8 us, t-delta = 12726.3 ns < T_chip -> chip 1 -> +1
    %   sample 130: t = 129/Fs = 12.9 us, t-delta = 12826.3 ns > T_chip -> chip 2 -> -1
    assert(c_B(129) == +1 && c_B(130) == -1, ...
           'P16d: transition boundary incorrect at chip boundary');
    fprintf('    P16d PASS: transition boundary correct at chip boundary\n');

    fprintf('  test_align_code_fractional: ALL PASS\n');
end
