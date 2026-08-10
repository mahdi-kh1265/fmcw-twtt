function run_all_tests()
% RUN_ALL_TESTS  Execute the complete V0/V1 test suite.
%
%   Calls every test function. Prints summary. Throws error if any fail.

    fprintf('\n--- V0/V1 Test Suite ---\n\n');

    tests = {@test_v0_single_link, ...
             @test_v1_two_way, ...
             @test_fractional_delay, ...
             @test_sign_convention, ...
             @test_waveform_closedform};

    names = {'test_v0_single_link (T01-T05)', ...
             'test_v1_two_way (T06-T09)', ...
             'test_fractional_delay (T10)', ...
             'test_sign_convention (T11-T12)', ...
             'test_waveform_closedform (T13)'};

    n_pass = 0;
    n_fail = 0;

    for i = 1:length(tests)
        try
            tests{i}();
            n_pass = n_pass + 1;
        catch e
            fprintf('  FAILED: %s\n    %s\n', names{i}, e.message);
            n_fail = n_fail + 1;
        end
    end

    fprintf('\n--- Results: %d passed, %d failed out of %d test groups ---\n', ...
            n_pass, n_fail, length(tests));

    if n_fail > 0
        error('run_all_tests:failure', '%d test group(s) failed.', n_fail);
    end
end
