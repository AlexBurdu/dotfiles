#!/usr/bin/env bash

# Backup existing mc config
mv ~/.config/mc ~/.config/mc.bak

# Create a symlink to the mc config
ln -s $(pwd) ~/.config/mc
