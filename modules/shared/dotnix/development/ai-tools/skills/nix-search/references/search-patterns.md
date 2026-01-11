# Advanced Search Patterns

This document covers advanced nix-search usage patterns for complex scenarios.

## Multi-Channel Comparison

When checking package availability or versions across channels:

```bash
# Check unstable
nix-search -c unstable terraform

# Check stable 24.05
nix-search -c 24.05 terraform

# Check stable 24.11
nix-search -c 24.11 terraform
```

**When to use:** User needs specific version, or package not found in default channel.

**Pattern:** Start with unstable (newest), fall back to stable releases if user needs reliability.

## Platform Availability Matrix

Check if package is available across different architectures:

```bash
# Linux x86_64 (most common)
nix-search --platform x86_64-linux <package>

# Linux ARM64
nix-search --platform aarch64-linux <package>

# macOS Apple Silicon
nix-search --platform aarch64-darwin <package>

# macOS Intel
nix-search --platform x86_64-darwin <package>
```

**When to use:** Cross-platform projects, user mentions specific architecture, or package not found on default platform.

**Common issue:** Some packages (especially proprietary software) may only be available on specific platforms.

## Complex Filtering

### Combine Multiple Filters

```bash
# Specific version on specific platform
nix-search --platform aarch64-darwin python3 -v "3.12"

# Specific channel and version
nix-search -c 24.05 nodejs -v "18.*"

# Program search on specific platform
nix-search -p terraform --platform x86_64-linux
```

### Wildcard Patterns

Wildcards only work with `-n` (name) and `-p` (program) searches:

```bash
# All Emacs packages
nix-search -n "emacsPackages.*"

# All AWS CLI tools
nix-search -p "aws*"

# Python packages starting with "py"
nix-search -n "py*"
```

**Note:** Wildcards don't work with general keyword searches or `-t options` searches.

## Pagination for Large Result Sets

### Understanding Limits

- Maximum total results: 10,000 (Elasticsearch limit)
- Default page size: 20 results
- Use pagination when: (1) initial search returns many results, (2) looking for less-common matches further down

### Pagination Commands

```bash
# Get first 50 results
nix-search -s 50 python

# Skip first 20, get next 20 (page 2)
nix-search --from 20 --size 20 python

# Skip first 100, get next 50
nix-search --from 100 --size 50 python
```

### Validation Rules

- `--size` must be > 0
- `--from` must be >= 0
- `--from + --size` must be \<= 10,000

**When to use:** Rarely needed in practice. Use more specific search terms instead of pagination when possible.

## JSON Output and Parsing

### Basic JSON Output

```bash
nix-search --json python3
```

Returns raw Elasticsearch response with all metadata.

### Parsing with jq

Extract specific fields:

```bash
# Get package attribute name
nix-search --json -n python3 | jq -r '.hits.hits[0]._source.package_attr_name'

# Get package version
nix-search --json -n python3 | jq -r '.hits.hits[0]._source.package_pversion'

# Get all program names
nix-search --json -p gcc | jq -r '.hits.hits[0]._source.package_programs[]'

# Get description
nix-search --json python3 | jq -r '.hits.hits[0]._source.package_description'

# Count total results
nix-search --json python | jq '.hits.total.value'
```

### Extract Multiple Results

```bash
# Get top 5 package names
nix-search --json -s 5 python | jq -r '.hits.hits[]._source.package_attr_name'

# Get name and version for all results
nix-search --json python | jq -r '.hits.hits[] | "\(.._source.package_attr_name) @ \(._source.package_pversion)"'
```

**When to use:** Rarely needed. Only use JSON when you need programmatic access to multiple fields or metadata that isn't shown in standard output.

## Output Formatting Options

### Detailed Output

Show more information per result:

```bash
nix-search -d python3
```

Includes: full description, all programs, licenses, maintainers, homepage.

### Compact Output

Remove spacing between results:

```bash
nix-search --compact python
```

Useful for fitting more results on screen.

### Reverse Sort

Show highest priority at bottom (easier to see in terminal):

```bash
nix-search -r python
```

### Pager Control

```bash
# Force pager (even for small results)
nix-search --pager python

# Disable pager (print all to stdout)
nix-search --no-pager python
```

Default: auto-detect based on output size and terminal.

## Error Recovery Strategies

### Package Not Found

**Strategy cascade:**

1. Try broader search without filters:

   ```bash
   # If this fails:
   nix-search -n specific-package-name

   # Try this:
   nix-search specific package
   ```

1. Check unstable channel:

   ```bash
   nix-search -c unstable <package>
   ```

1. Try different search types:

   ```bash
   nix-search -p <name>  # If -n failed
   nix-search <keywords>  # If both failed
   ```

1. Check for typos or alternate names:

   - `node` vs `nodejs`
   - `go` vs `golang`
   - `python` vs `python3`

### Ambiguous Program Name

When multiple packages provide the same program:

```bash
# Example: "python" could be python2 or python3
nix-search -p python
```

**Response strategy:**

1. Show top 2-3 matches
1. Ask user which they meant
1. Don't guess - ambiguity should be resolved by user

### Version Not Available

```bash
# Requested version not in channel
nix-search -c 24.05 nodejs -v "20.*"
```

**Recovery:**

1. Check unstable: `nix-search -c unstable nodejs -v "20.*"`
1. Show available versions: `nix-search -c 24.05 nodejs`
1. Suggest closest match
1. Explain channel differences if needed

### Platform Unavailable

```bash
# Package not available for requested platform
nix-search --platform aarch64-darwin proprietary-tool
```

**Recovery:**

1. Try x86_64 version (may work via Rosetta on macOS)
1. Check if different package provides same functionality
1. Check unstable channel
1. Inform user of platform limitations

## Options Search Patterns

### Exact Option

```bash
nix-search -t options "services.nginx.enable"
```

### Option Prefix

```bash
# All nginx-related options
nix-search -t options "services.nginx"

# All firewall options
nix-search -t options "networking.firewall"

# All boot options
nix-search -t options "boot"
```

### Option Discovery

When user describes what they want:

```bash
# User: "I want to configure SSH"
nix-search -t options "services.openssh"

# User: "I need GPU support"
nix-search -t options "hardware.opengl"
nix-search -t options "hardware.nvidia"
```

## Flakes Search Patterns

Flakes search is less structured than packages:

```bash
# General search
nix-search -t flakes <keyword>

# Examples:
nix-search -t flakes home-manager
nix-search -t flakes wayland
nix-search -t flakes rust
```

**Note:** Flakes search quality varies. May need broader terms than package search.

## Performance Considerations

### When to Use Each Search Type

- **Fastest:** `-n` (name) and `-p` (program) - exact attribute matching
- **Medium:** keyword search - full-text search across descriptions
- **Slower:** options search with wildcards - broader matching
- **Variable:** flakes search - depends on index size

### Reducing Result Set

Instead of paginating through large results, narrow the search:

```bash
# Too broad (1000+ results):
nix-search python

# Better:
nix-search python -v "3.12"
nix-search "python web framework"
nix-search -n "python3*"
```

## Custom Base URL

For self-hosted search.nixos.org instances:

```bash
nix-search --base-url https://custom.search.instance.org python3
```

**When to use:** Enterprise setups, custom Nix repositories, testing.
