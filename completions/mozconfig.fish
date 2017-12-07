

complete -xc mozconfig -n '__fish_is_first_token' -a 'help' -d "Print usage info"

complete -xc mozconfig -n '__fish_is_first_token' -a 'show' -d "Show current mozconfig"
complete -xc mozconfig -n '__fish_is_first_token' -a 'new' -d "Create new mozconfig"
complete -xc mozconfig -n '__fish_is_first_token' -a 'use' -d "Change mozconfigs"
complete -xc mozconfig -n '__fish_is_first_token' -a 'list' -d "List active mozconfigs"
complete -xc mozconfig -n '__fish_is_first_token' -a 'edit' -d "Edit mozconfig"

complete -xc mozconfig -n '__fish_seen_subcommand_from use' -a '(mozconfig list)'
complete -xc mozconfig -n '__fish_seen_subcommand_from edit' -a '(mozconfig list)'

complete -xc buildwith -a "(command ls $BUILDWITH_HOME)" -d "Set mozconfig"

if test -e $BUILDWITH_HOME/.active
  complete -xc buildwith -a "(basename (mozconfig))" -d "current mozconfig"
end


if test -e $BUILDWITH_HOME/.active
  complete -xc buildwith -a "(command cat $BUILDWITH_HOME/.active)" -d "current mozconfig"
end


