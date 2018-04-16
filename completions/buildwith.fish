
complete -xc buildwith -a "(mozconfig list -q)"

if test -e $HOME/.mozconfigs/.active
  complete -xc buildwith -a "(basename (mozconfig show))" -d "current"
end
