# Performance Optimization Opportunities

This document identifies potential performance improvements for the fMRI task template.

## Current Performance Characteristics

**Startup time** (from script start to first flip):
- Config loading + validation: ~50ms
- Trial list generation: ~100-500ms (depends on numTrials)
- Image preloading: ~2-10s (depends on numImages and resolution)
- PTB initialization: ~500ms-2s
- **Total**: ~3-12 seconds

**Per-trial overhead**:
- Display trial + flip: ~1-5ms
- Response logging: ~0.1-1ms per key press
- Fixation + flip: ~1-5ms
- **Total**: ~2-11ms per trial (negligible vs stimulus duration)

## Optimization Opportunities

### 1. Image Preloading (High Impact) ⭐⭐⭐

**Current**: Images loaded synchronously during startup via `loadImages`.

**Issue**: Large image datasets (>50 images) can take 5-10 seconds to load and resize.

**Optimization**:
```matlab
% Option A: Lazy loading (load on-demand during trial)
% - Set params.preloadImages = false in config.m
% - Images loaded only when needed
% - Reduces startup time from 10s → 0.5s
% - Trade-off: First presentation of each image has ~100ms delay

% Option B: Parallel loading (requires Parallel Computing Toolbox)
function imMat = loadImagesParallel(trialList, params)
    parfor i = 1:numel(trialList)
        imMat(i) = loadSingleImage(trialList(i).stimuli, params);
    end
end
% - 2-4x speedup on multi-core systems
% - Requires Parallel Computing Toolbox
```

**Recommendation**: For studies with >30 images, use lazy loading or implement parallel loading.

### 2. Trial List Generation (Medium Impact) ⭐⭐

**Current**: `makeTrialList` reads TSV file and builds struct array.

**Issue**: For large experiments (>500 trials), struct array operations can be slow (~500ms).

**Optimization**:
```matlab
% Use table2struct only at the end (tables are faster for row operations)
function trialList = makeTrialListOptimized(params, in)
    % Work with table throughout
    stimTable = readtable(...);

    % Replicate as table (faster)
    trialTable = repmat(stimTable, params.numRepetitions, 1);

    % Add columns as vectors (vectorized)
    trialTable.trialNb = (1:height(trialTable))';
    trialTable.run = ceil(trialTable.trialNb / trialsPerRun);

    % Convert to struct only at end
    trialList = table2struct(trialTable);
end
```

**Expected speedup**: ~2-3x for large trial lists (500+ trials).

### 3. Input Queue Polling (Low Impact) ⭐

**Current**: `logKeyPressDual` polls both queues in tight loop.

**Issue**: Polling overhead ~0.01ms per iteration; negligible but adds up over long fixations.

**Optimization**:
```matlab
% Add sleep to reduce CPU usage during long waits
while conditionFunc(0)
    % Check queues
    [~, ~, ~, queueState] = KbQueueCheck(inputDevs.trigger);
    % ... process events

    % Sleep briefly if no events and more than 10ms remaining
    if isempty(events) && (GetSecs - startTime) < (duration - 0.01)
        WaitSecs(0.001);  % 1ms sleep reduces CPU from 100% → 50%
    end
end
```

**Expected benefit**: Reduces CPU usage; no timing impact. Good for battery life on laptops.

### 4. Logging Performance (Low Impact) ⭐

**Current**: `logEvent` calls `fprintf` for each event; file handle flushed automatically by MATLAB.

**Issue**: For experiments with many events (>1000), file I/O can add ~1-2ms per event.

**Optimization**:
```matlab
% Buffer log events in memory, flush at end of trial
persistent logBuffer;
if isempty(logBuffer), logBuffer = {}; end

logBuffer{end+1} = sprintf('%s\t%s\t...', eventType, eventName, ...);

% Flush every N events or at trial end
if mod(numel(logBuffer), 50) == 0 || isEndOfTrial
    for i = 1:numel(logBuffer)
        fprintf(logFile, '%s\n', logBuffer{i});
    end
    logBuffer = {};
end
```

**Expected speedup**: ~2-3ms per trial (50 events); negligible unless >200 trials.

**Risk**: Data loss if script crashes before flush. Not recommended for production.

### 5. Screen Setup (Low Impact) ⭐

**Current**: `setupScreen` always opens window, computes PPD, configures colors.

**Issue**: Multiple calls during development waste time (~500ms per call).

**Optimization**:
```matlab
% Cache PTB window across dev_smoke runs (persistent variable)
persistent cachedWin;
if ~isempty(cachedWin) && Screen('WindowKind', cachedWin) == 1
    win = cachedWin;
    % Skip window creation
else
    win = Screen('OpenWindow', ...);
    cachedWin = win;
end
```

**Expected benefit**: Faster dev iteration when running multiple quick tests.

**Risk**: Window state may become stale. Only use in development scripts like dev_smoke.

### 6. Texture Management (Medium Impact) ⭐⭐

**Current**: `displayTrial` calls `Screen('MakeTexture', ...)` on preloaded images each trial.

**Issue**: If images are already preloaded as matrices, `MakeTexture` is called redundantly.

**Optimization**:
```matlab
% Option A: Preload as textures (not matrices)
function imMat = loadImagesAsTextures(trialList, params, win)
    for i = 1:numel(trialList)
        im = imread(trialList(i).stimuli);
        imMat(i).texture = Screen('MakeTexture', win, im);  % Store texture handle
    end
end

% Then in displayTrial:
if isfield(image, 'texture')
    Screen('DrawTexture', win, image.texture);  % Use cached texture
else
    % Fallback to matrix-based rendering
    texture = Screen('MakeTexture', win, image.data);
    Screen('DrawTexture', win, texture);
    Screen('Close', texture);
end
```

**Expected speedup**: ~2-5ms per trial (eliminates MakeTexture overhead).

**Trade-off**: Textures consume GPU memory; may hit limits with >100 large images.

**Risk**: Textures must be closed at end (`Screen('Close', texture)`).

### 7. Drift Compensation Calculation (Negligible)

**Current**: `adjustFixationDuration` called per trial, computes timing delta.

**Overhead**: ~0.01ms per trial. Negligible.

**Recommendation**: No optimization needed.

## Priority Recommendations

### For Development/Testing:
1. ⭐⭐⭐ **Use lazy loading** (`params.preloadImages = false`) for fast iteration
2. ⭐⭐ **Add WaitSecs(0.001) in input polling** to reduce CPU usage

### For Production (Scanner):
1. ⭐⭐⭐ **Parallel image loading** if >30 images (requires Parallel Computing Toolbox)
2. ⭐⭐ **Preload as textures** if GPU memory allows (saves 2-5ms per trial)
3. ⭐⭐ **Optimize trial list generation** if >500 trials

### Not Recommended:
- Buffered logging (risk of data loss)
- Cached PTB windows (state management complexity)

## Measurement Tools

To profile your specific experiment:

```matlab
% Add to fMRI_task.m after line 141 (after logging init):
tic;
logEvent(logFile, 'PROFILE', 'StartupStart', dateTimeStr, '-', GetSecs - in.scriptStart, '-', '-');

% After image loading (line ~137):
logEvent(logFile, 'PROFILE', 'ImagesLoaded', dateTimeStr, '-', GetSecs - in.scriptStart, '-', toc);

% In trial loop (after each trial):
logEvent(logFile, 'PROFILE', sprintf('Trial%d', i), dateTimeStr, '-', GetSecs - in.scriptStart, '-', toc);
```

Then analyze log file to identify bottlenecks.

## Summary

**Most impactful** optimizations:
1. Image loading strategy (lazy vs parallel)
2. Texture preloading (if GPU memory allows)
3. Trial list generation (for large experiments)

**Expected total speedup**:
- Startup: 3-12s → 0.5-5s (lazy loading)
- Per-trial: No significant change (already <11ms overhead)
- CPU usage: 100% → 50% (input polling sleep)

Most experiments will see the biggest benefit from **lazy image loading** or **parallel loading**.
