# Fish completions for the Vercel CLI.

set -l vercel_basic_commands deploy build cache dev env git help init inspect install integration integration-resource link list login logout open promote pull redeploy rollback switch
set -l vercel_advanced_commands activity agent ai-gateway agent-runs alerts alias api bisect blob buy certs connect contract cron crons curl deploy-hooks dns domains firewall flags global-config httpstat logs metrics mcp microfrontends oauth-apps projects redirects remove routes rolling-release rr sandbox skills target teams telemetry tokens traces upgrade usage vcr webhooks whoami

complete -c vercel -e
complete -c vc -e

for command in $vercel_basic_commands
    complete -c vercel -n '__fish_use_subcommand' -a $command -f
    complete -c vc -n '__fish_use_subcommand' -a $command -f
end

for command in $vercel_advanced_commands
    complete -c vercel -n '__fish_use_subcommand' -a $command -f
    complete -c vc -n '__fish_use_subcommand' -a $command -f
end

for command in $vercel_basic_commands $vercel_advanced_commands
    complete -c vercel -n "__fish_seen_subcommand_from $command" -l help -s h -d 'Output usage information'
    complete -c vc -n "__fish_seen_subcommand_from $command" -l help -s h -d 'Output usage information'
end

for command in vercel vc
    complete -c $command -n '__fish_use_subcommand' -l help -s h -d 'Output usage information'
    complete -c $command -n '__fish_use_subcommand' -l version -s v -d 'Output the version number'
    complete -c $command -l cwd -r -d 'Current working directory'
    complete -c $command -l local-config -s A -r -F -d 'Path to the local vercel.json file'
    complete -c $command -l global-config -s Q -r -a '(__fish_complete_directories)' -d 'Path to the global .vercel directory'
    complete -c $command -l debug -s d -d 'Debug mode'
    complete -c $command -l no-color -d 'No color mode'
    complete -c $command -l non-interactive -d 'Run without interactive prompts'
    complete -c $command -l scope -s S -r -d 'Set a custom scope'
    complete -c $command -l token -s t -r -d 'Login token'
end