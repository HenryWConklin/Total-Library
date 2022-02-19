#!/bin/sh
echo "Checking gdscript formatting"
if ! git diff --cached --name-only --diff-filter=AM $against | grep ".gd$" | xargs --no-run-if-empty gdformat
then
  echo "Formatting issues detected, update with formatting before commiting"
  exit 1
fi

echo "Checking gdscript lints"
if ! git diff --cached --name-only --diff-filter=AM $against | grep ".gd$" | xargs --no-run-if-empty gdlint
then
  echo "Lint issues detected, fix before commiting"
  exit 1
fi

echo "Running unit tests"
if ! godot -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -gexit --verbose
then
  echo "Unit tests failed, fix before commiting"
  exit 1
fi
