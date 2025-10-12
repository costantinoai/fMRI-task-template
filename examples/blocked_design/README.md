# Blocked Design Example

This example demonstrates a simple blocked fMRI design with 3 conditions (A, B, C) alternating across 4 blocks per run.

## Design

- **3 conditions**: Category A, Category B, Category C
- **4 blocks per run**: 12 trials per block (48 trials total)
- **Block order**: A → B → C → A (fixed)
- **Stimulus duration**: 2s
- **ISI**: 1s (fixation between trials)
- **Block duration**: 36s (12 trials × 3s)
- **Total run time**: ~4 minutes

## Files

- `makeTrialListBlocked.m` - Custom trial list generator for blocked design
- `list_of_stimuli_blocked.tsv` - Stimulus list with condition labels
- `config_blocked.m` - Configuration file (copy to `src/config.m`)

## Usage

1. **Copy stimulus list**:
   ```bash
   cp examples/blocked_design/list_of_stimuli_blocked.tsv src/list_of_stimuli.tsv
   ```

2. **Copy config**:
   ```bash
   cp examples/blocked_design/config_blocked.m src/config.m
   ```

3. **Copy trial list generator**:
   ```bash
   cp examples/blocked_design/makeTrialListBlocked.m src/
   ```

4. **Edit fMRI_task.m** (line ~131):
   ```matlab
   % OLD:
   trialList = makeTrialList(params, in);

   % NEW:
   trialList = makeTrialListBlocked(params, in);
   ```

5. **Prepare your stimuli**:
   - Add images to `src/stimuli/`
   - Label each image with condition in TSV (condA, condB, condC)

6. **Run**:
   ```matlab
   % Debug mode first
   fMRI_task  % Set debugMode=true in script

   % Scanner mode
   fMRI_task  % Set debugMode=false, fmriMode=true
   ```

## Analysis

Block onsets can be extracted from the log file:

```matlab
log = readtable('data/sub-01/..._log.tsv', 'FileType', 'text');

% Find block transitions
blockStarts = find(diff([0; trial_block]) ~= 0);
blockOnsets = log.ACTUAL_ONSET(blockStarts);

% blocks = [1 1 1 ... 2 2 2 ... 3 3 3 ... 4 4 4]
%           ↑ block 1  ↑ block 2  ↑ block 3  ↑ block 4
```

## Customization

- **Change block order**: Edit `blockOrder` in `makeTrialListBlocked.m`
- **Variable block lengths**: Adjust `trialsPerBlock` per condition
- **Randomize within blocks**: Shuffle trials within each block
- **Add jitter**: Vary fixation duration per trial
