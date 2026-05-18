# Gem Version Update and Installation Guide

This document explains how to:

1. Update the gem version
2. Build the gem
3. Install (or reinstall) it locally

## 1. Update Gem Version

Current gem version is set in `commiti.gemspec`:

```ruby
spec.version = "0.1.0"
```

Change it to the next version, for example:

```ruby
spec.version = "0.1.1"
```

### Recommended Versioning

Use Semantic Versioning:

- Patch (`0.1.1`): bug fixes, no breaking API changes
- Minor (`0.2.0`): backward-compatible features
- Major (`1.0.0`): breaking changes

## 2. Build the Gem

From the project root:

```bash
gem build commiti.gemspec
```

This creates a file like:

```text
commiti-0.1.1.gem
```

## 3. Install the Gem Locally

Install the newly built gem:

```bash
gem install ./commiti-1.0.7.gem
```

Then verify:

```bash
commiti --help
```

## Reinstall After Another Change

If you iterate often, repeat:

1. Bump `spec.version`
2. Rebuild with `gem build commiti.gemspec`
3. Install the new `.gem` file

## Optional Cleanup (Old Local Versions)

List installed versions:

```bash
gem list commiti
```

Uninstall an old one:

```bash
gem uninstall commiti -v 0.1.0
```

## Run From Source Without Installing

For development, you can run directly:

```bash
bundle install
bundle exec ruby -Ilib bin/commiti --help
```

This is useful for quick testing before publishing/installing a new gem build.
