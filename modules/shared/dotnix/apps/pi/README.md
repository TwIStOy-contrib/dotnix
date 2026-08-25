# Pi static settings

When `dotnix.apps.pi.enable` is true, Home Manager publishes two JSON files for `htw pi-config`:

```text
$HOME/.config/htw/pi-config/recommended.json
$HOME/.config/htw/pi-config/enforced.json
```

Both documents are strict JSON objects. Their values come from `dotnix.apps.pi.recommendedSettings` and `dotnix.apps.pi.enforcedSettings`, respectively. Empty and nested objects are valid.

The public `pi` command reconciles these files with Pi's writable settings before and after every invocation. Use `pi-real` to invoke the platform-adjusted Pi binary directly for diagnostics, bypassing reconciliation while retaining the configured editor and API-key environment.
