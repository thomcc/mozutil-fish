
function gecko_root
  argparse -n gecko_root 'q/quiet' 'r/require' -- $argv
  if set -q GECKO
    set gecko (realpath $GECKO)
    if string match -q $gecko\* $PWD; and not set -q _flag_require
      if not set -q _flag_quiet; echo $GECKO; end
      return 0
    end
  end
  set -l path $PWD
  while test $path != "."; and test $path != "/"
    if test -x $path/mach; and test -d $path/xpcom # distinctive enough.
      if not set -q _flag_quiet; echo $path; end
      return 0
    end
    set path (dirname $path)
  end
  if set -q GECKO; and not set -q _flag_quiet
    echo $GECKO
  end
  return 1
end
