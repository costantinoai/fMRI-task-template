#!/bin/bash
# CHECK_INVARIANTS Verify output invariants haven't been violated.
#
# Checks:
# - logEvent function signature and column order
# - File naming patterns in createLogFile
# - Event name constants
# - .mat variable names in saveAndClose
#
# Used by pre-commit hooks to prevent accidental breakage.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "Checking output invariants..."

# Check logEvent TSV header
if ! grep -q "EVENT_TYPE.*EVENT_NAME.*DATETIME.*EXP_ONSET.*ACTUAL_ONSET.*DELTA.*EVENT_ID" utils/recording/logEvent.m; then
    echo "ERROR: logEvent header order changed! Output invariant violated."
    exit 1
fi

# Check createLogFile naming pattern
if ! grep -q "YYYY-MM-DD-hh-mm_sub-.*_run-.*_task-" utils/recording/createLogFile.m; then
    echo "ERROR: Log file naming pattern changed! Output invariant violated."
    exit 1
fi

# Check event name constants exist
EVENTS="Instr TgrWait Pre-fix Stim Fix Post-fix RESP FLIP INFO ERROR"
for event in $EVENTS; do
    if ! grep -q "$event" fMRI_task.m; then
        echo "WARNING: Event name '$event' not found in main script."
    fi
done

# Check .mat variables
if ! grep -q "params.*in.*runTrials.*runImMat" utils/recording/saveAndClose.m; then
    echo "ERROR: .mat variable structure changed! Output invariant violated."
    exit 1
fi

echo "✓ All output invariants verified"
exit 0
