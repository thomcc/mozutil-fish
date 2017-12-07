
if test -f $HOME/.mozconfigs/.active
  set -l active (cat "$HOME/.mozconfigs/.active")
  if not test -z "$active"
    mozconfig use $active -q
  end
end
