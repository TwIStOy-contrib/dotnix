# Pi static settings

When `dotnix.apps.pi.enable` is true, Home Manager publishes two JSON files for `htw pi-config`:

```text
$HOME/.config/htw/pi-config/recommended.json
$HOME/.config/htw/pi-config/enforced.json
```

Both documents are strict JSON objects. Their values come from `dotnix.apps.pi.recommendedSettings` and `dotnix.apps.pi.enforcedSettings`, respectively. Empty and nested objects are valid.
