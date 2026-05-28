# SCratchpad: Spectral Analysis Plan for vosk_bridge.py

## Goal
Replace VOSK word-based ASR with raw spectral analysis for detecting sustained "Rrrr" trill/phoneme from a WAV file.

## Current State
- File: scripts/vosk_bridge.py (244 lines)
- Already contains STFT-based spectral analysis (not actually using VOSK library)
- Uses `scipy.signal.spectrogram` to compute magnitude spectrogram
- Analyzes energy ratio in R-formant band (800-2200 Hz) per frame
- Heuristic: 25% R-band energy threshold, 65% continuity fraction, 60ms minimum sustained run
- Already has: read_wav, compute_r_spectral_energy, detect_r_trill, main()

## Analysis Approach (current implementation)
1. Read 16-bit mono WAV, normalize to [-1, 1], resample to 16 kHz
2. Compute STFT with 32ms windows, 20ms overlap
3. For each frame: compute ratio of energy in 800-2200 Hz band to total energy
4. Also compute voiced energy (80-400 Hz) for voicing detection
5. Determine per-frame R-activity (ratio > 0.25)
6. Check continuity fraction across active frames
7. Check for sustained runs (max consecutive R-active frames >= 3)
8. Final decision: has_r_trill, r_intensity (0-1), is_continuous, is_silent

## Plan: Refinements for better detection

### Phase 1: Improved Preprocessing
- Add bandpass pre-filter (80-4000 Hz) to remove noise before STFT
- Add onset detection to trim leading/trailing silence automatically
- Add RMS-based VAD with adaptive threshold (not just fixed 0.008)

### Phase 2: Enhanced Spectral Features
- Compute spectral centroid per frame (R phoneme has lowered F3)
- Compute spectral flatness (fricative vs voiced discrimination)
- Compute zero-crossing rate for trill detection (rapid amplitude modulation)
- Detect low-frequency periodicity (8-15 Hz) = trill rate via autocorrelation

### Phase 3: Robust Decision Logic
- Replace fixed threshold with logistic regression on feature vector
- Use hysteresis for onset/offset detection (avoid flutter)
- Return confidence score instead of binary classification
- Add debug mode with per-frame feature export

### Phase 4: Performance
- Pre-allocate numpy arrays
- Use batch processing for multiple files (stdin streaming mode)
- Add optional audio chunk overlap for real-time mode

## Output Fields
- has_r_trill: bool
- r_intensity: float 0-1
- is_continuous: bool
- is_silent: bool
- detection_detail: {
    rms, continuity, avg_r_ratio, max_consecutive_run,
    active_frames, r_active_frames, total_frames,
    spectral_centroid_mean, flatness_mean,
    trill_rate (if detected)
  }