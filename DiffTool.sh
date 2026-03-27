#!/bin/bash

# ============================================
# Git Difftool Script for CAD Taylor project
# 
# Usage:
#   One commit vs HEAD:        ./gitdiff.sh <commit1>
#   Two specific commits:      ./gitdiff.sh <commit1> <commit2>
#
# Example:
#   ./gitdiff.sh 7c06268
#   ./gitdiff.sh 7c06268 a1b2c3d
# ============================================

PROJECT="CAD Taylor"

# Check if at least one commit hash was provided
if [ -z "$1" ]; then
    echo "-------------------------------------------"
    echo " Git Difftool - CAD Taylor"
    echo "-------------------------------------------"
    echo " Usage:"
    echo "   One commit vs HEAD:    ./gitdiff.sh <commit1>"
    echo "   Two specific commits:  ./gitdiff.sh <commit1> <commit2>"
    echo ""
    echo " Example:"
    echo "   ./gitdiff.sh 7c06268"
    echo "   ./gitdiff.sh 7c06268 a1b2c3d"
    echo "-------------------------------------------"
    exit 1
fi

COMMIT1=$1

# Check if a second commit was provided
if [ -z "$2" ]; then
    # Compare commit1 vs HEAD
    COMMIT2="HEAD"
    echo "-------------------------------------------"
    echo " Comparing:"
    echo "   FROM: $COMMIT1"
    echo "   TO:   HEAD (current version)"
    echo "   IN:   $PROJECT"
    echo "-------------------------------------------"
else
    # Compare commit1 vs commit2
    COMMIT2=$2
    echo "-------------------------------------------"
    echo " Comparing:"
    echo "   FROM: $COMMIT1"
    echo "   TO:   $COMMIT2"
    echo "   IN:   $PROJECT"
    echo "-------------------------------------------"
fi

git difftool -d "$COMMIT1" "$COMMIT2" -- "$PROJECT"
