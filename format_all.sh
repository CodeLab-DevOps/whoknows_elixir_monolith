#!/bin/bash
# Script to format all Elixir files before pushing to CI

echo "Installing dependencies..."
mix deps.get

echo "Formatting all files..."
mix format

echo "Done! All files are now formatted."
echo "You can now commit and push your changes."
