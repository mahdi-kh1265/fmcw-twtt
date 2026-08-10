> **ARCHIVE NOTE (2026-08-10):** This was the pre-build acquisition checklist. The repository has since been built; see `../00_START_HERE/ARCHIVE_STATUS_2026-08-10.md` for the final status of this acquisition pass.

# FMCW / TWTT Literature Acquisition Status — 2026-08-10

This is a staging checklist only. The final ZIP/repository has **not** been built yet.

## Current staging status

- 54 locally staged PDFs/documents are available for reading and classification.
- The staging corpus already covers: FMCW fundamentals, TI/AWR2944 implementation, DCA1000/raw data, MATLAB/MathWorks radar modeling, TWTT and clock synchronization, distributed/coherent radar, coded FMCW/PMCW, phase noise, chirp nonlinearity, precision estimation/CRLB, calibration/coherency, and recent distributed-array synchronization.
- Final packaging will separate redistributable/open-license documents from citation-only or user-supplied restricted papers.

## P0 — Please obtain/upload these first

These are the highest-priority missing sources for the Saeed FMCW-TWTT simulation and the later 10-ps analysis.

| # | Year | Paper | Identifier | Why it matters |
|---|---:|---|---|---|
| 1 | 2007 | S. Röhr, P. Gulden, M. Vossiek, **Method for High Precision Clock Synchronization in Wireless Systems with Application to Radio Navigation** | DOI `10.1109/RWS.2007.351890` | Foundational cooperative radio clock-synchronization paper from the Vossiek lineage. |
| 2 | 2007 | S. Röhr, M. Vossiek, P. Gulden, **Method for High Precision Radar Distance Measurement and Synchronization of Wireless Units** | DOI `10.1109/MWSYM.2007.380436` | Direct predecessor to cooperative FMCW synchronization/ranging. |
| 3 | 2008 | A. Stelzer, M. Jahn, S. Scheiblhofer, **Precise Distance Measurement with Cooperative FMCW Radar Units** | DOI `10.1109/RWS.2008.4463606` | Core unsynchronized cooperative-FMCW ranging paper. |
| 4 | 2008 | S. Röhr, P. Gulden, M. Vossiek, **Precise Distance and Velocity Measurement for Real Time Locating in Multipath Environments Using a Frequency-Modulated Continuous-Wave Secondary Radar Approach** | DOI `10.1109/TMTT.2008.2003137` | Detailed secondary/cooperative FMCW timing, range, velocity, and multipath treatment. |
| 5 | 2008 | S. Scheiblhofer, S. Schuster, M. Jahn, R. Feger, A. Stelzer, **A Versatile FMCW Radar System Simulator for Millimeter-Wave Applications** | DOI `10.1109/EUMC.2008.4751778` | One of the most directly relevant MATLAB/system-simulation precedents. |
| 6 | 2008 | S. Scheiblhofer, S. Schuster, M. Jahn, R. Feger, A. Stelzer, **Performance Analysis of Cooperative FMCW Radar Distance Measurement Systems** | DOI `10.1109/MWSYM.2008.4633118` | Performance limits and phase-noise behavior of cooperative FMCW. |
| 7 | 2013 | R. Feger et al., **A 77-GHz Cooperative Radar System Based on Multi-Channel FMCW Stations for Local Positioning Applications** | DOI `10.1109/TMTT.2012.2227781` | 77-GHz hardware demonstration; bridges the foundational work toward our 77-GHz implementation. |
| 8 | 2019 | M. Gottinger, F. Kirsch, P. Gulden, M. Vossiek, **Coherent Full-Duplex Double-Sided Two-Way Ranging and Velocity Measurement Between Separate Incoherent Radio Units** | DOI `10.1109/TMTT.2019.2902553` | **Extremely important:** full-duplex, double-sided two-way FMCW ranging between independent clocks; arguably the closest academic paper to Saeed's immediate concept. |
| 9 | 2016 | S. Ayhan et al., **Impact of Frequency Ramp Nonlinearity, Phase Noise, and SNR on FMCW Radar Accuracy** | DOI `10.1109/TMTT.2016.2599165` | Required for a non-bullshit impairment model and accuracy budget. |
| 10 | 2015 | S. Scherr et al., **An Efficient Frequency and Phase Estimation Algorithm With CRB Performance for FMCW Radar Applications** | DOI `10.1109/TIM.2014.2381354` | Required for sub-bin / CRLB-level beat-frequency and phase estimation. |
| 11 | 2012 | S. Scherr, S. Ayhan, M. Pauli, T. Zwick, **Accuracy Limits of a K-Band FMCW Radar with Phase Evaluation** | IEEE document `6450702` | Derives CRLB and compares FFT/CZT/ESPRIT; directly relevant to picosecond-level estimation thinking. |
| 12 | 2012 | R. Ebelt, D. Shmakov, M. Vossiek, **The Effect of Phase Noise on Ranging Uncertainty in FMCW Secondary Radar-Based Local Positioning Systems** | EuRAD 2012, pp. 258–261 | Directly addresses phase-noise-limited ranging in secondary/cooperative FMCW. |
| 13 | 2018 | F. Herzel, D. Kissinger, H. J. Ng, **Analysis of Ranging Precision in an FMCW Radar Measurement Using a Phase-Locked Loop** | DOI `10.1109/TCSI.2017.2733041` | Precision model tying PLL behavior to FMCW ranging. |
| 14 | 2022 | P. Tschapek et al., **Detailed Analysis and Modeling of Phase Noise and Systematic Phase Distortions in FMCW Radar Systems** | DOI `10.1109/JMW.2022.3195574` | Modern, detailed phase-noise/systematic-error model; CC BY 4.0. |
| 15 | 1992 | A. G. Stove, **Linear FMCW Radar Techniques** | DOI `10.1049/ip-f-2.1992.0048` | Classic FMCW reference; useful for fundamentals and notation sanity checks. |
| 16 | 2023 | B. Lettner, **FMCW Radar Transceiver Synchronization in a Multistatic Microwave Tomography System** (JKU thesis) | JKU thesis / institutional repository | Deep, thesis-length synchronization reference; repository is open but our downloader is blocked. |

## P1 — Strongly useful second-wave papers

| Year | Paper | Identifier / status | Why it matters |
|---:|---|---|---|
| 2020 | M. Gottinger et al., CFDDS-TWR follow-up on phase tracking / multipath suppression | DOI `10.1109/IMS30576.2020.9224105` | Extends the 2019 two-way ranging method into very fine coherent displacement/phase tracking. |
| 2021 | M. Gottinger, P. Gulden, M. Vossiek, **Coherent Signal Processing for Loosely Coupled Bistatic Radar** | DOI `10.1109/TAES.2021.3050650` | Bistatic coherency despite separate radar units; very relevant to two-AWR hardware later. |
| 2021 | M. Gottinger et al., **Coherent Automotive Radar Networks: The Next Generation of Radar-Based Imaging and Mapping** | DOI `10.1109/JMW.2020.3034475`; CC BY 4.0 | Broad radar-network architecture/synchronization review from the same research lineage. |
| 2020 | A. Dürr et al., **Calibration-Based Phase Coherence of Incoherent and Quasi-Coherent 160-GHz MIMO Radars** | DOI `10.1109/TMTT.2020.2971187`; CC BY 4.0 | Calibration-based route to coherence with separate synthesizers. |
| 2024 | D. Werbunat et al., **On the Synchronization of Uncoupled Multistatic PMCW Radars** | DOI `10.1109/TMTT.2024.3359035`; CC BY 4.0 | Digital carrier/timing recovery for uncoupled radar nodes; important coded-waveform analog to our future phase-coded FMCW. |
| 2024 | L. Sigg et al., **Over-the-Air Synchronization for Coherent Digital Automotive Radar Networks** | DOI `10.1109/TRS.2024.3449333` | Modern OTA synchronization correcting carrier, sampling, and timing offsets. |
| 2024 | V. Janoudi et al., **Signal Model for Coherent Processing of Uncoupled and Low Frequency Coupled MIMO Radar Networks** | DOI `10.1109/JMW.2023.3334757` | Excellent error/signal model for uncoupled radar networks. |
| 2015 | **A New Multistatic FMCW Radar Architecture by Over-the-Air Deramping** | DOI `10.1109/JSEN.2015.2466477` | Conceptual precedent for using over-the-air dechirping/deramping to simplify distributed radar processing. |
| 2013 | R. Thurn, R. Ebelt, M. Vossiek, **Noise in Homodyne FMCW Radar Systems and Its Effects on Ranging Precision** | DOI `10.1109/MWSYM.2013.6697654` | Noise/CRLB treatment for precision FMCW estimation. |
| 2003 | T. Musch, **A High Precision 24-GHz FMCW Radar Based on a Fractional-N Ramp-PLL** | DOI `10.1109/TIM.2003.810046` | Classic high-linearity ramp source / precision ranging implementation. |
| 1993 | **Range Correlation Effects in Radars** | DOI `10.1109/NRC.1993.270463` | Foundational phase-noise range-correlation background. |
| 2022 | P. Tschapek et al., **A Novel Approach for Modeling and Digital Generation of RF Signals Distorted by Bandlimited Phase Noise** | DOI `10.1109/JMW.2022.3188166` | Useful for generating physically meaningful phase noise in our simulator. |
| 2022 | P. Tschapek et al., **Phase Noise Spectral Density Measurement of Broadband Frequency-Modulated Radar Signals** | DOI `10.1109/TMTT.2022.3148311` | Useful when we later measure/model the real AWR chirp phase noise. |

## Already staged locally — 54 files

- `2014_Frischen_Hasch_Waldschmidt_Cooperative_Radar_Uncorrelated_Phase_Noise.pdf`
- `2014_MathWorks_Design_of_FMCW_Radars_for_Active_Safety_Applications.pdf`
- `2014_Rajan_van_der_Veen_Joint_Ranging_Synchronization_Anchorless_Mobile_Network.pdf`
- `2015_Dwivedi_Joint_Ranging_Clock_Parameter_Estimation_Two_Way_RTT.pdf`
- `2015_ITU_TF1153_Two_Way_Satellite_Time_Frequency_Transfer.pdf`
- `2016_Honeywell_EP2985625A1_FMCW_Radar_with_Timing_Synchronization.pdf`
- `2016_Honeywell_US20160047892A1_FMCW_Radar_Phase_Encoded_Data_Channel.pdf`
- `2016_Lopez_Martinez_Vidal_Morera_Simulation_FMCW_Radar_SDR.pdf`
- `2016_MathWorks_Radar_System_Design_Using_MATLAB_Simulink.pdf`
- `2016_Scheiblhofer_In_Chirp_FSK_Communication_Cooperative_77GHz_Radar.pdf`
- `2017_TI_Complex_Baseband_Architecture_in_FMCW_Radar_Systems.pdf`
- `2018_Kazaz_Joint_Ranging_Clock_Synchronization_Dense_IoT.pdf`
- `2018_Park_Park_Park_Leakage_Mitigation_Internal_Delay_Compensation_FMCW.pdf`
- `2018_Svensson_High_Resolution_Frequency_Estimation_FMCW_Radar_Thesis.pdf`
- `2018_TI_MIMO_Radar_RevA.pdf`
- `2019_MathWorks_Automotive_Radar_Development_MATLAB.pdf`
- `2019_Mueller_Diewald_Cooperative_Radar_Signature_Unambiguity.pdf`
- `2019_Wang_et_al_Range_Accuracy_FMCW_Source_Nonlinearity.pdf`
- `2020_Infineon_US20200132825A1_Phase_Coded_FMCW_Radar.pdf`
- `2020_Lampel_System_Level_Synchronization_Phase_Coded_FMCW_RadCom.pdf`
- `2020_UIUC_FMCW_Radar_Lecture.pdf`
- `2020_Uysal_Orru_Phase_Coded_FMCW_Application_and_Challenges.pdf`
- `2020_Uysal_Phase_Coded_FMCW_System_Design_Interference_Mitigation.pdf`
- `2022_Architectures_and_Synchronization_Techniques_Distributed_Satellite_Systems_Survey.pdf`
- `2022_Duerr_Coherent_Multistatic_MIMO_Radar_Network_Phase_Noise_Optimized_Synthesis.pdf`
- `2022_MIT_Radar_and_Coherent_Sensor_Processing_Lecture.pdf`
- `2022_Merlo_Mghabghab_Nanzer_Wireless_Picosecond_Time_Synchronization.pdf`
- `2022_TI_Interference_Mitigation_for_AWR_IWR_Devices.pdf`
- `2023_Merlo_High_Accuracy_Wireless_Time_Frequency_Transfer_Distributed_Beamforming.pdf`
- `2023_Tagliaferri_et_al_Cooperative_Coherent_Multistatic_Imaging_Phase_Synchronization.pdf`
- `2024_Ahmadi_et_al_Distributed_Massive_MIMO_FMCW_Radar_Simulator_Ray_Tracing.pdf`
- `2024_Chen_Niknejad_RF_Domain_Leakage_Cancellation_FMCW_Radars.pdf`
- `2024_Decentralized_Picosecond_Synchronization_Distributed_Arrays.pdf`
- `2024_Huang_et_al_Overview_Millimeter_Wave_Radar_Modeling_Methods.pdf`
- `2024_Kou_Bauduin_Bourdoux_Pollin_Distributed_PMCW_Radar_Network_Phase_Noise.pdf`
- `2024_Multi_Objective_Distributed_Beamforming_High_Accuracy_Sync.pdf`
- `2024_Shandi_Merlo_Nanzer_Wireless_Picosecond_Time_Synchronization_Dynamic_Connectivity.pdf`
- `2024_TI_AWR294x_Device_Errata.pdf`
- `2024_TI_AWR294x_Technical_Reference_Manual_RevD.pdf`
- `2025_BIPM_Time_Dissemination_TWSTFT_Lecture.pdf`
- `2025_DLR_Investigation_CW_LFM_Waveforms_Bi_Multistatic_Radar_Synchronization.pdf`
- `2025_Eid_Novel_Simulation_Technique_UWB_FMCW_Radar.pdf`
- `2025_Han_Meng_Masouros_OTA_Time_Frequency_Synchronization_Distributed_ISAC.pdf`
- `2025_Multistatic_Radar_Performance_Distributed_Wireless_Synchronization_BCRLB.pdf`
- `2025_Real_Time_High_Accuracy_Digital_Wireless_Time_Frequency_Phase_Synchronization.pdf`
- `2025_TI_Getting_Started_with_mmWave_Sensors.pdf`
- `2026_TI_AWR2943_AWR2944_Datasheet_RevE.pdf`
- `2026_UCSB_Introduction_to_mmWave_Radar_Sensing_Lab_Notes.pdf`
- `Merlo_Picosecond_NLOS_Wireless_Time_Frequency_Transfer_Presentation.pdf`
- `NIST_Fundamentals_of_Two_Way_Time_Transfers_by_Satellite.pdf`
- `TI_Cascade_Coherency_and_Phase_Shifter_Calibration.pdf`
- `TI_Fundamentals_of_mmWave_Radar_Sensors.pdf`
- `TI_Programming_Chirp_Parameters_Radar_Devices.pdf`
- `TI_Self_Calibration_mmWave_Radar_Devices.pdf`
