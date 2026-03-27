#!/bin/bash

# ============================================
# Git Difftool Script for CAD Taylor project
# Usage: ./gitdiff.sh <commit-hash>
# Example: ./gitdiff.sh 7c06268
# ============================================

# Check if a commit hash was provided
if [ -z "$1" ]; then
    echo "Usage: ./gitdiff.sh <commit-hash>"
    echo "Example: ./gitdiff.sh 7c06268"
    exit 1
fi

COMMIT=$1
PROJECT="CAD Taylor"

echo "Comparing commit $COMMIT with current HEAD in '$PROJECT'..."
git difftool -d "$COMMIT" HEAD -- "$PROJECT"
