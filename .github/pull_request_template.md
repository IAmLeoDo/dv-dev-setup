<!-- Keep the description focused on the final change. Remove unused prompts.
     See CONTRIBUTING.md for branch, validation and platform requirements. -->

## Problem and change

<!-- Explain the problem, the resulting behavior and why this approach fits.
     Include a before/after example for changes to commands or configuration. -->

## Related issue

<!-- Link an issue when one exists. Use "Closes #123" only if this PR resolves it. -->

## Validation

<!-- Record actual commands and results. Use "Not run: reason" or "Not applicable"
     instead of implying that an unavailable platform passed. Documentation-only
     changes can report link, example and formatting checks. -->

| Check | Command / environment | Result |
| --- | --- | --- |
| Bash syntax and ShellCheck | `bash src/scripts/check/check.sh` | |
| Source and packaged behavior | | |
| Windows CMD and PowerShell | | |
| macOS packaging | | |

<!-- For setup changes, describe dry-run and dedicated VM/machine results,
     including a second run and preservation of existing configuration/data.
     If a check already fails on the base branch, identify the existing failure
     and provide evidence; do not disable checks to hide it. -->

## Compatibility and remaining limitations

<!-- Note changed arguments, configuration, paths or dependencies; migration
     steps; and checks still needed. Write "None" when appropriate. -->

## Checklist

<!-- Tick applicable items; explain any item left unchecked. -->

- [ ] The change is focused, and the description reflects the final implementation.
- [ ] Documentation and help examples match changed behavior, or are unaffected.
- [ ] Runtime allowlists are updated for added/moved files, or are unaffected.
- [ ] Validation results and unavailable platforms are recorded above.
- [ ] Generated bundles and incidental local version bumps are excluded; intentional release changes are explained.
