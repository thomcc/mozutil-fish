
# imperfect but good enough and easier to come up with
function __mach_try_print_platforms
  for p in all linux linux64 linux64-pgo linux64-asan \
      linux64-st-an linux64-valgrind linux64-haz macosx64 macosx64-st-an \
      win32 win32-pgo win32-st-an win32-mingw32 win64 win64-pgo win64-st-an \
      android-api-16 android-api-16-gradle android-x86 android-aarch64 sm-arm-sim \
      sm-compacting sm-plain sm-rootanalysis linux64-ccov linux64-shell-haz;
    echo $p
  end
end

function __mach_try_print_talos
  set -l list none all chromez-e10s dromaeojs-e10s other-e10s g1-e10s g2-e10s \
      svgr-e10s tp5o-e10s tp6-e10s tp6-stylo-e10s tp6-stylo-threads-e10s xperf-e10s
  for p in $list
    echo $p
  end
end

function __mach_try_print_tests
  set -l list all reftest reftest-e10s reftest-no-accel crashtest \
    crashtest-e10s xpcshell jsreftest marionette marionette-e10s \
    marionette-headless marionette-headless-e10s awsy-e10s mozmill \
    cppunit gtest firefox-ui-functional mochitest; # todo: more?
  for p in $list
    echo $p
  end
end

complete -xc mach -n '__fish_is_first_token' -a '(mach mach-commands)'

# for subcmd in run bootstrap build;
#   complete -c mach -n "__fish_use_subcommand" -a $subcmd -x 
# end

# complete -c mach -n "" -s v -l verbose -d "Print verbose output."
# complete -c mach -n "" -s h -l help -d "Show help"

# complete -c mach -n "" -l log-interval -d "Prefix log line with interval from previous"
# complete -c mach -n "" -l log-no-times -d "Do not prefix log lines with times."

# complete -c mach -n "" -s l -l log-file -r -d "Filename to write log data to."

# complete -c mach -n "" -l debug-command -d "Start a Python debugger when command is dispatched"
# complete -c mach -n "" -l settings -r -d "Path to settings file.."

# complete -c mach -n "__fish_use_subcommand" -xa "build" -d "Build browser";
# complete -c mach -n "__fish_use_subcommand" -xa "run"  -d "Run browser";
# complete -c mach -n "__fish_use_subcommand" -xa "try" -d "push to try";
# complete -c mach -n "__fish_use_subcommand" -a "xpcshell-test" -d "Run xpcshell test";

complete -c mach -n "__fish_seen_subcommand_from build" -a "faster binaries"
complete -c mach -n "__fish_seen_subcommand_from build" -s j -l jobs
complete -c mach -n "__fish_seen_subcommand_from build" -s X -l disable-extra-make-dependencies
complete -c mach -n "__fish_seen_subcommand_from build" -s C -l directory -r

complete -c mach -n "__fish_seen_subcommand_from run" -l remote -s r -f
complete -c mach -n "__fish_seen_subcommand_from run" -l background -s b -f
complete -c mach -n "__fish_seen_subcommand_from run" -l noprofile -s n -f
complete -c mach -n "__fish_seen_subcommand_from run" -l debug -f
complete -c mach -n "__fish_seen_subcommand_from run" -l debugger -x
complete -c mach -n "__fish_seen_subcommand_from run" -l debugger-args -x

for argopt in verify-max-time jsdebugger-port debugger app-path threads dump-tests \
    manifests symbols-path xre-path total-chunks this-chunk debugger-args tag;
  complete -c mach -n "__fish_seen_subcommand_from xpcshell-test" -l $argopt -r
end

for noargopt in jsdebugger interactive logfiles no-logfiles verify shuffle rerun-failures sequential;
  complete -c mach -n "__fish_seen_subcommand_from xpcshell-test" -l $noargopt
end

complete -c mach -n "__fish_seen_subcommand_from try" -a "fuzzy empty syntax"
complete -c mach -n "__fish_seen_subcommand_from try" -s b -xa "d o do od"

complete -c mach -n "__fish_seen_subcommand_from try" -s p -fa "(__fish_complete_list , __mach_try_print_platforms)"
complete -c mach -n "__fish_seen_subcommand_from try" -s u -fa "(__fish_complete_list , __mach_try_print_tests)"
complete -c mach -n "__fish_seen_subcommand_from try" -s t -fa "(__fish_complete_list , __mach_try_print_talos)"
complete -c mach -n "__fish_seen_subcommand_from try" -l artifact -d "Enable artifact build"
complete -c mach -n "__fish_seen_subcommand_from try" -l no-artifact -d "Disable artifact build"

complete -c mach -n "__fish_seen_subcommand_from try" -a "mozharness:\ --geckoProfile" -d "enable profiling"

# todo: more, docs, etc.
