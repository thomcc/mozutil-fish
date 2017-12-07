
function mach -d "Mozilla build system interface"
  if command -s mach
    command mach $argv
  else if test -x $PWD/mach
    eval $PWD/mach $argv
  else
    set -l geckopath (gecko_root)
    set -l mach_path mach
    if test -x $geckopath/mach
      set mach_path $geckopath/mach
    else if test -n "$MACH"
      set mach_path $MACH
    else
      echo "Error: Mach not found. Try setting GECKO or MACH to point to one, or moving to a gecko root"
    end
    eval $mach_path $argv
  end
end

