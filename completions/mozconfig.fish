

complete -xc mozconfig -n '__fish_is_first_token' -a 'help' -d "Print usage info"

complete -xc mozconfig -n '__fish_is_first_token' -a 'show' -d "Show current mozconfig"
complete -xc mozconfig -n '__fish_is_first_token' -a 'new' -d "Create new mozconfig"
complete -xc mozconfig -n '__fish_is_first_token' -a 'use' -d "Change mozconfigs"
complete -xc mozconfig -n '__fish_is_first_token' -a 'list' -d "List active mozconfigs"
complete -xc mozconfig -n '__fish_is_first_token' -a 'edit' -d "Edit mozconfig"

complete -xc mozconfig -n '__fish_seen_subcommand_from use' -a '(mozconfig list -q)' -d "change"
complete -xc mozconfig -n '__fish_seen_subcommand_from edit' -a '(mozconfig list -q)'

complete -xc buildwith -a "(mozconfig list -q)" -d "Set mozconfig"

if test -e $HOME/.mozconfigs/.active
  complete -xc buildwith -a "(basename (mozconfig show))" -d "current"
  complete -xc mozconfig -n '__fish_seen_subcommand_from use' -a '(basename (mozconfig show))' -d "current"
  complete -xc mozconfig -n '__fish_seen_subcommand_from edit' -a '(basename (mozconfig show))' -d "current"
end
