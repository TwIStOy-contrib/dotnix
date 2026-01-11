# Nix Configuration

This repo contains all machine setup and configuration since this is a NixOS system - system packages, services, dotfiles, and home-manager config are all declared here.

## Tools

Use the `justfile` for common tasks and commands.
Run `just check` after making changes to validate the configuration.
Run `just` to deploy changes (builds and activates the new configuration).
