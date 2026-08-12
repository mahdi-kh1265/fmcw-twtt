% run_all.m
% Master entry point for V0/V1/V2a/V2b FMCW timing simulation.
%
% Establishes paths relative to this script, runs all tests,
% then runs all demos (which generate figures and results).
%
% Usage (from any working directory):
%   >> run('path/to/10_SIMULATION_WORKSPACE/matlab/run_all.m')
%
% Or from within this directory:
%   >> run_all
%
% Exits cleanly only if all tests pass.
%
% Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Section E.2

%% Establish paths relative to this script
this_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(this_dir, 'src'));
addpath(fullfile(this_dir, 'tests'));
addpath(fullfile(this_dir, 'scripts'));

%% Ensure output directories exist
if ~exist(fullfile(this_dir, 'figures'), 'dir')
    mkdir(fullfile(this_dir, 'figures'));
end
if ~exist(fullfile(this_dir, 'results'), 'dir')
    mkdir(fullfile(this_dir, 'results'));
end

%% Run tests (stop on failure)
fprintf('=== Running Tests ===\n');
run_all_tests;

%% Run demos
fprintf('\n=== Running Demos ===\n\n');
demo_v0_single_link;
fprintf('\n');
demo_v1_two_way;
fprintf('\n');
demo_fig05_spectrum_family;
fprintf('\n');
demo_fig06_slope_sensitivity;

fprintf('\n--- V2a (CFO) ---\n\n');
demo_v2a_cfo;

fprintf('\n--- V2b (Phase Coding) ---\n\n');
demo_v2b_coding;

%% Done
fprintf('\n=== ALL DONE -- V0/V1/V2a/V2b PASS ===\n');
