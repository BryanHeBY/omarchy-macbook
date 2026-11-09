# Installation profiles

`recommended.json` is the source of recommended activation defaults.
`input_method` selects `caps-fn` or `shift`. `features` maps every supported
feature directory name to a JSON boolean. The root installer validates the
complete feature set before running any commands.

Command-line options override the corresponding recommended selections.
Feature helpers support targeted configuration after installation. The input
profile selects a complete keyboard behavior; the Shift variant restores the
original primary Left Shift trigger.

Selections describe installation and activation work. Existing user configuration
for other features is retained. Each complete run applies the selected input
profile and two-finger state. See the [installation guide](../docs/installation.md)
for deactivation and recovery behavior.
