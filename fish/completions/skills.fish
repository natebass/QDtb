set -l skills_commands add use remove list ls find update experimental_install init experimental_sync

complete -c skills -f -n 'not __fish_seen_subcommand_from $skills_commands' -a "$skills_commands"
complete -c skills -s h -l help -d 'Display help'
complete -c skills -s v -l version -d 'Display version'

complete -c skills -n '__fish_seen_subcommand_from add' -s g -l global -d 'Install globally'
complete -c skills -n '__fish_seen_subcommand_from add' -s a -l agent -r -d 'Target agent'
complete -c skills -n '__fish_seen_subcommand_from add' -s s -l skill -r -d 'Select skills'
complete -c skills -n '__fish_seen_subcommand_from add' -s l -l list -d 'List available skills'
complete -c skills -n '__fish_seen_subcommand_from add' -l all -d 'Install all skills'
complete -c skills -n '__fish_seen_subcommand_from add' -l full-depth -d 'Fetch full repository history'
complete -c skills -n '__fish_seen_subcommand_from add' -s y -l yes -d 'Skip confirmation'

complete -c skills -n '__fish_seen_subcommand_from use' -s s -l skill -r -d 'Select skill'
complete -c skills -n '__fish_seen_subcommand_from use' -s a -l agent -r -d 'Target agent'
complete -c skills -n '__fish_seen_subcommand_from use' -l full-depth -d 'Fetch full repository history'

complete -c skills -n '__fish_seen_subcommand_from remove' -s g -l global -d 'Remove globally'
complete -c skills -n '__fish_seen_subcommand_from remove' -s a -l agent -r -d 'Target agent'
complete -c skills -n '__fish_seen_subcommand_from remove' -s s -l skill -r -d 'Select skills'
complete -c skills -n '__fish_seen_subcommand_from remove' -l all -d 'Remove all skills'
complete -c skills -n '__fish_seen_subcommand_from remove' -s y -l yes -d 'Skip confirmation'

complete -c skills -n '__fish_seen_subcommand_from list ls' -s g -l global -d 'List globally installed skills'
complete -c skills -n '__fish_seen_subcommand_from list ls' -s a -l agent -r -d 'Target agent'
complete -c skills -n '__fish_seen_subcommand_from list ls' -l json -d 'Output JSON'

complete -c skills -n '__fish_seen_subcommand_from find' -l owner -r -d 'Filter by owner'
complete -c skills -n '__fish_seen_subcommand_from update' -s g -l global -d 'Update globally'
complete -c skills -n '__fish_seen_subcommand_from update' -s p -l project -d 'Update project skills'
complete -c skills -n '__fish_seen_subcommand_from update' -s y -l yes -d 'Skip confirmation'
complete -c skills -n '__fish_seen_subcommand_from experimental_sync' -s a -l agent -r -d 'Target agent'
complete -c skills -n '__fish_seen_subcommand_from experimental_sync' -s y -l yes -d 'Skip confirmation'
