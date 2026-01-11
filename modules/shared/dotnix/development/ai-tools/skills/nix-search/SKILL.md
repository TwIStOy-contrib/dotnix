---
name: nix-search
description: Use when helping users find Nix packages, NixOS configuration options, or flakes. Triggers when writing nix code, answering questions about installing software with nix, searching for which package provides a binary/program, looking up nixos options, finding package versions or platform availability, discovering flakes
---

# nix-search

## Overview

Use the `nix-search` CLI tool to search packages, options, and flakes from search.nixos.org. Run searches proactively whenever you need package information - don't ask permission for read-only searches.

## When To Use

Use when helping users find Nix packages, NixOS configuration options, or flakes. Triggers when:

1. writing Nix code (flake.nix, configuration.nix) that needs package names,
2. answering questions about installing software with Nix,
3. searching for which package provides a binary/program,
4. looking up NixOS options for system configuration,
5. finding package versions or platform availability,
6. discovering flakes. Be proactive - automatically search when you need package information rather than asking the user.

## Core Search Patterns

### Search by Binary/Program Name

When users ask "what package provides X?" or need a specific binary:

```bash
nix-search -p <program-name>
```

**Examples:**

- `nix-search -p gcc` - Find package providing gcc compiler
- `nix-search -p terraform` - Find Terraform package
- `nix-search -p "aws*"` - Find AWS-related programs (wildcards supported)

**After finding:** Provide installation commands based on context.

### Search by Package Attribute Name

When writing Nix code or verifying exact package names:

```bash
nix-search -n <package-name>
```

**Examples:**

- `nix-search -n python3` - Find python3 package
- `nix-search -n "emacsPackages.*"` - Find Emacs packages (wildcards supported)
- `nix-search -n terraform` - Get exact attribute name

**After finding:** Use the attribute name directly in Nix code.

### Search by Keywords

For general discovery when users describe what they need:

```bash
nix-search "<description keywords>"
```

**Examples:**

- `nix-search "python linter"` - Find Python linting tools
- `nix-search "web browser"` - Find browser packages
- `nix-search golang` - Find Go-related packages

**After finding:** Show relevant options, let user clarify if needed.

### Search NixOS Options

When users ask about system configuration:

```bash
nix-search -t options "<option-pattern>"
```

**Examples:**

- `nix-search -t options "networking.firewall"` - Find firewall options
- `nix-search -t options "services.nginx"` - Find nginx configuration options
- `nix-search -t options boot` - Find boot-related options

**After finding:** Provide configuration.nix example with the option.

### Search Flakes

When users need to discover flakes:

```bash
nix-search -t flakes <query>
```

**Examples:**

- `nix-search -t flakes wayland` - Find Wayland-related flakes
- `nix-search -t flakes home-manager` - Find home-manager flakes

### Platform-Specific Search

When architecture matters:

```bash
nix-search --platform <arch> <query>
```

**Platforms:** x86_64-linux, aarch64-linux, aarch64-darwin, x86_64-darwin, i686-linux, armv7l-linux, riscv64-linux, powerpc64le-linux

**Example:**

- `nix-search --platform aarch64-darwin python3` - Check if Python 3 is available for Apple Silicon

### Channel-Specific Search

To check specific NixOS releases:

```bash
nix-search -c <channel> <query>
```

**Common channels:** unstable, 24.11, 24.05, 23.11, 23.05

**Example:**

- `nix-search -c 24.05 firefox` - Find Firefox in stable 24.05
- `nix-search -c unstable nodejs` - Find latest Node.js

### Version Search

To find or verify specific versions:

```bash
nix-search <package> -v "<version-pattern>"
```

**Examples:**

- `nix-search golang -v "1.21"` - Find Go version 1.21
- `nix-search terraform -v "1.*"` - Find Terraform 1.x versions

## Contextual Actions

After running searches, take appropriate action based on context:

### Context: Writing flake.nix

**Detect:** Editing flake.nix or user asks to modify flake
**Action:** Insert package attribute directly into code

```nix
# User: "Add terraform to my devShell"
# → Run: nix-search -n terraform
# → Insert into flake.nix:
{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      terraform
    ];
  };
}
```

### Context: Writing configuration.nix

**Detect:** Editing configuration.nix or user asks about system packages
**Action:** Add to environment.systemPackages or appropriate service configuration

```nix
# User: "Install firefox system-wide"
# → Run: nix-search -n firefox
# → Insert:
environment.systemPackages = with pkgs; [
  firefox
];
```

### Context: Interactive Q&A

**Detect:** User asking "how do I install X?" or "what package has Y?"
**Action:** Show package info with installation commands

```
# User: "How do I install gcc?"
# → Run: nix-search -p gcc
# → Response:
The gcc package provides the GCC compiler collection.

Install temporarily (for current shell):
  nix shell nixpkgs#gcc

Install persistently:
  nix profile install nixpkgs#gcc

Or add to your flake.nix or configuration.nix
```

### Context: NixOS Options Lookup

**Detect:** Questions about "how do I configure X?" or "what's the option for Y?"
**Action:** Provide configuration example

```
# User: "How do I enable the firewall?"
# → Run: nix-search -t options "networking.firewall.enable"
# → Response:
Add to your configuration.nix:

networking.firewall.enable = true;
networking.firewall.allowedTCPPorts = [ 80 443 ];
```

### Context: Version or Platform Questions

**Detect:** Questions about "is X available for Y?" or "what version of Z?"
**Action:** Check across channels/platforms and report

```
# User: "Is Python 3.12 available for ARM?"
# → Run: nix-search --platform aarch64-linux python3 -v "3.12"
# → Report availability and recommend channel if needed
```

## Common Scenarios

### "How do I install X?"

1. Run `nix-search -p X` or `nix-search X`
1. Show package description
1. Provide installation commands (shell/profile/flake)

### "What package has the Y binary?"

1. Run `nix-search -p Y`
1. Show matching packages with descriptions
1. If multiple matches, show top 2-3, let user choose if ambiguous

### "Add Z to my development environment"

1. Run `nix-search -n Z` to verify package exists
1. Detect which file (flake.nix, shell.nix)
1. Add package to appropriate packages list

### "How do I configure W service?"

1. Run `nix-search -t options "services.W"`
1. Show relevant options with types and descriptions
1. Provide configuration.nix example

### "Is package X available for my platform?"

1. Run `nix-search --platform <arch> X`
1. If not found, try unstable channel
1. Report availability or suggest alternatives

## Error Handling

### No Results Found

1. Try broader search terms
1. Remove filters (version, platform)
1. Check spelling
1. Search in unstable channel
1. Suggest similar packages if available

### Multiple Ambiguous Matches

1. Show top 2-3 results with brief descriptions
1. Let user clarify which one they want
1. Don't guess - ask if unclear

### Platform Unavailable

1. Check if available on other platforms
1. Try unstable channel
1. Inform user of availability constraints
1. Suggest alternatives if possible

### Version Not Found

1. Show available versions
1. Suggest closest match
1. Check unstable channel for newer versions

## Output Control

### Silent Searches

Run searches without announcing them. Just show results or integrate into code/answers.

### Detailed Information

Use `-d` flag when user needs more details:

```bash
nix-search -d python3
```

### JSON Output

For programmatic parsing (rare, only if needed for complex logic):

```bash
nix-search --json python3
```

## Advanced Patterns

For advanced scenarios (pagination, complex filtering, JSON parsing), see [references/search-patterns.md](references/search-patterns.md).

## Key Principles

1. **Be proactive** - Search automatically when you need package info
1. **Context-aware** - Different actions for code vs. Q&A
1. **Silent operation** - Don't announce searches, just use results
1. **Handle errors gracefully** - Try alternatives, suggest solutions
1. **Verify before writing** - Always check package exists before adding to code
