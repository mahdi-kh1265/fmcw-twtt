# FMCW / TWTT Research Corpus - Archive Status (2026-08-10)



The current acquisition and synthesis pass is complete enough to begin the MATLAB V0/V1 implementation.

- **84 bibliography records** are cataloged in `bibliography.csv`.
- **70 physical source/reference PDFs** are present in the archive after SHA-256 de-duplication.
- The 70 source/reference PDFs include the topical acquisition library, project-context documents, and **11 unique user-supplied publisher/restricted papers** kept only under `09_RESTRICTED_OR_CITATION_ONLY/user_supplied_restricted/`.
- **12 high-priority P0/P1 sources remain citation-only.** These are valuable additions for later deep prior-art/error-budget work, but they are not blockers for the ideal FMCW/TWTT V0/V1 simulation.
- **6 synthesis/guide PDFs (121 pages total)** are included: master index, annotated source atlas, literature/prior-art review, mathematical handbook, MATLAB simulation blueprint, and recommended reading order.
- **36 unique PDFs** were added from the pre-existing 54-file staging library during final packaging; byte-identical duplicates were not copied twice.

## Six synthesis PDFs

1. `MASTER_INDEX.pdf` - project framing, corpus map, source-status conventions, high-priority bibliography, detailed P0/P1 source cards, decisions, and questions for Saeed.
2. `FMCW_TWTT_Annotated_Source_Atlas.pdf` - **43-page, source-by-source atlas for all 84 bibliography records**, including status, DOI, archive location, why each source matters, what to extract, and a notebook prompt.
3. `FMCW_TWTT_Literature_and_Prior_Art_Review.pdf` - detailed lineage from classical FMCW/stretch processing through cooperative synchronization, CFDDS-TWR, coherent radar networks, coded FMCW, and picosecond wireless synchronization.
4. `FMCW_TWTT_Mathematical_Handbook.pdf` - derivations, assumptions, timing/clock models, estimators, nonidealities, error propagation, and AWR-oriented numerical sanity checks.
5. `AWR2944_FMCW_TWTT_MATLAB_Simulation_Blueprint.pdf` - staged code architecture, module contracts, test matrix, plots, estimator ladder, impairment plan, and AWR mapping.
6. `recommended_reading_order.pdf` - compact route through the corpus.

## Remaining citation-only P0/P1 sources

The same list is machine-readable in `CITATION_ONLY_WISHLIST.csv`.

- **Method for High Precision Clock Synchronization in Wireless Systems with Application to Radio Navigation** (2007) - 10.1109/RWS.2007.351890
- **Precise Distance Measurement with Cooperative FMCW Radar Units** (2008) - 10.1109/RWS.2008.4463606
- **Precise Distance and Velocity Measurement for Real Time Locating in Multipath Environments Using a Frequency-Modulated Continuous-Wave Secondary Radar Approach** (2008) - 10.1109/TMTT.2008.2003137
- **Performance Analysis of Cooperative FMCW Radar Distance Measurement Systems** (2008) - 10.1109/MWSYM.2008.4633118
- **A 77-GHz Cooperative Radar System Based on Multi-Channel FMCW Stations for Local Positioning Applications** (2013) - 10.1109/TMTT.2012.2227781
- **Accuracy Limits of a K-Band FMCW Radar with Phase Evaluation** (2012) - identifier not recorded
- **The Effect of Phase Noise on Ranging Uncertainty in FMCW Secondary Radar-Based Local Positioning Systems** (2012) - identifier not recorded
- **Linear FMCW Radar Techniques** (1992) - 10.1049/ip-f-2.1992.0048
- **FMCW Radar Transceiver Synchronization in a Multistatic Microwave Tomography System** (2023) - identifier not recorded
- **On the Synchronization of Uncoupled Multistatic PMCW Radars** (2024) - 10.1109/TMTT.2024.3359035
- **Over-the-Air Synchronization for Coherent Digital Automotive Radar Networks** (2024) - 10.1109/TRS.2024.3449333
- **Signal Model for Coherent Processing of Uncoupled and Low Frequency Coupled MIMO Radar Networks** (2024) - 10.1109/JMW.2023.3334757

## Copyright/source handling

User-supplied publisher PDFs are isolated in the restricted folder and are not duplicated into topical folders. Other research copies remain in topical folders for the private project archive; inclusion does not assert redistribution permission. The bibliography preserves citations even when PDF bytes are absent.

## Next project step

Implement **MATLAB Simulation V0/V1** exactly as specified in `AWR2944_FMCW_TWTT_MATLAB_Simulation_Blueprint.pdf`: analytic complex-baseband chirp phase, continuous fractional delay, ideal dechirp, an FFT view for intuition, a phase-slope/least-squares sub-bin estimator, then reciprocal A-to-B/B-to-A recovery of propagation delay and clock offset. Do not add coded FMCW or detailed phase-noise models until the ideal tests pass.
