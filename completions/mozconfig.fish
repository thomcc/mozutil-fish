function __mozutil_complete_is_first_arg
  test (count (commandline -poc)) -eq 1
end

complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -a 'help' -d "Print usage info"

complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -a 'show' -d "Show current mozconfig"
complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -a 'new' -d "Create new mozconfig"
complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -a 'use' -d "Change mozconfigs"
complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -a 'list' -d "List active mozconfigs"
complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -a 'edit' -d "Edit mozconfig"
complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -s e -d "Edit mozconfig"

complete -xc mozconfig -n '__fish_seen_subcommand_from use' -a '(mozconfig list -q)' -d "change"
complete -xc mozconfig -n '__fish_seen_subcommand_from edit -e' -a '(mozconfig list -q)'

complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -s e -d "Edit mozconfig"
complete -xc mozconfig -n '__mozutil_complete_is_first_arg' -s m -d "Edit mozconfig"

if test -e $HOME/.mozconfigs/.active
  complete -xc mozconfig -n '__fish_seen_subcommand_from use' -a '(basename (mozconfig show))' -d "current"
  complete -xc mozconfig -n '__fish_seen_subcommand_from edit -e' -a '(basename (mozconfig show))' -d "current"
end
