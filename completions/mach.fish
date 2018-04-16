
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

function __mach_needs_command
  set cmd (commandline -opc)
  if test (count $cmd) -eq 1
    return 0
  else
    set -l skip_next 0
    for c in $cmd[2..-1]
      if test $skip_next -eq 1
        set skip_next 0
        continue
      end
      switch $c
      case -v --{debug-command,verbose,log-{interval,no-times}} {--log-file,--settings,-l}'=*'
        # we can still take a command
        continue
      case --log-file --settings -l
        # these take an argument (the --blah=file version handled above)
        set skip_next 0
        continue
      case -h --help
        return 1
      case "*"
        echo $c
        return 1
      end
    end
    return 0
  end
  return 1
end

function __mach_find_xpcshelltests
  # set -l root (gecko_root)
  # find $root -type f -name xpcshell.ini -not -path $root'/obj*' -print0 | while read -z -l file
  #   set -l dir (dirname $file | string replace "$root/" "")
  #   cat $file | string replace -fr '^\[([^\]]+.js)\]' $dir'/$1'
  # end | sort | uniq
  for file in (git ls-files '*/xpcshell.ini')
    set -l dir (dirname $file)
    set -l tests (cat $file | string replace -fr '^\s*\[([^\]]+.js)\]' $dir'/$1')
    printf "%s\t%d tests\n" $dir (count $tests)
    for test in $tests
      printf "%s\tRun test\n" $test
    end
  end
end

function __mach_complete_xpcshelltests
  switch "$__mach_complete_cache_xpcshelltests"
  case "yes" "y" "1"
    if not set -q __mach_complete_xpcshelltest_cache[1]
      set -g __mach_complete_xpcshelltest_cache (__mach_find_xpcshelltests)
    end
    for item in $__mach_complete_xpcshelltest_cache
      echo $item
    end
  case "*"
    __mach_find_xpcshelltests
  end
end


# complete -xc mach -n '__mach_needs_command' -a '(mach mach-commands)'
# todo: -x/-r/-f for rest of these



complete -fc mach -n '__mach_needs_command' -a android-emulator -d "Run the Android emulator with an AVD from test automation."
complete -fc mach -n '__mach_needs_command' -a artifact -d "Use pre-built artifacts to build Firefox."
complete -c mach -n '__mach_needs_command' -a autophone -d "Run autophone."
complete -c mach -n '__mach_needs_command' -a awsy-test -d "Run Are We Slim Yet (AWSY) memory usage testing using marionette."
complete -c mach -n '__mach_needs_command' -a bootstrap -d "Install required system packages for building."
complete -fc mach -n '__mach_needs_command' -a build -d "Build the tree."
complete -fc mach -n '__mach_needs_command' -a build-backend -d "Generate a backend used to build the tree."
complete -fc mach -n '__mach_needs_command' -a buildsymbols -d "Produce a package of Breakpad-format symbols."
complete -c mach -n '__mach_needs_command' -a cargo -d "Invoke cargo in useful ways."
complete -c mach -n '__mach_needs_command' -a check-spidermonkey -d "Run SpiderMonkey tests (JavaScript engine)."
complete -c mach -n '__mach_needs_command' -a clang-complete -d "Generate a .clang_complete file."
complete -c mach -n '__mach_needs_command' -a clang-format -d "Run clang-format on current changes."
complete -c mach -n '__mach_needs_command' -a clobber -d "Clobber the tree (delete the object directory)."
complete -c mach -n '__mach_needs_command' -a compare-locales -d "Run source checks on a localization."
complete -c mach -n '__mach_needs_command' -a compileflags -d "Display the compilation flags for a given source file"
complete -c mach -n '__mach_needs_command' -a configure -d "Configure the tree (run configure and config.status)."
complete -c mach -n '__mach_needs_command' -a cppunittest -d "Run cpp unit tests (C++ tests)."
complete -c mach -n '__mach_needs_command' -a cramtest -d "Mercurial style .t tests for command line applications."
complete -c mach -n '__mach_needs_command' -a crashtest -d "Run crashtests (Check if crashes on a page)."
complete -c mach -n '__mach_needs_command' -a devtools-css-db -d "Rebuild the devtools static css properties database."
complete -c mach -n '__mach_needs_command' -a doc -d "Generate and display documentation from the tree."
complete -c mach -n '__mach_needs_command' -a doctor -d "Run the doctor."
complete -c mach -n '__mach_needs_command' -a dxr -d "Search for something in DXR."
complete -c mach -n '__mach_needs_command' -a empty-makefiles -d "Find empty Makefile.in in the tree."
complete -c mach -n '__mach_needs_command' -a environment -d "Show info about the mach and build environment."
complete -c mach -n '__mach_needs_command' -a eslint -d "Run eslint or help configure eslint for optimal development."
complete -c mach -n '__mach_needs_command' -a file-info -d "Query for metadata about files."
complete -c mach -n '__mach_needs_command' -a find-test-chunk -d "Find which chunk a test belongs to (works for mochitest)."
complete -c mach -n '__mach_needs_command' -a firefox-ui-functional -d "Run the functional test suite of Firefox UI tests."
complete -c mach -n '__mach_needs_command' -a firefox-ui-update -d "Run the update test suite of Firefox UI tests."
complete -c mach -n '__mach_needs_command' -a geckodriver -d "Run the WebDriver implementation for Gecko."
complete -c mach -n '__mach_needs_command' -a geckodriver-test -d "Run geckodriver unit tests."
complete -c mach -n '__mach_needs_command' -a google -d "Search for something on Google."
complete -c mach -n '__mach_needs_command' -a gradle -d "Run gradle."
complete -c mach -n '__mach_needs_command' -a gtest -d "Run GTest unit tests (C++ tests)."
complete -c mach -n '__mach_needs_command' -a ide -d "Generate a project and launch an IDE."
complete -c mach -n '__mach_needs_command' -a install -d "Install the package on the machine, or on a device."
complete -c mach -n '__mach_needs_command' -a jsapi-tests -d "Run jsapi tests (JavaScript engine)."
complete -c mach -n '__mach_needs_command' -a jstestbrowser -d "Run js/src/tests in the browser."
complete -c mach -n '__mach_needs_command' -a lint -d "Run linters."
complete -c mach -n '__mach_needs_command' -a mach-commands -d "List all mach commands."
complete -c mach -n '__mach_needs_command' -a mach-debug-commands -d "Show info about available mach commands."
complete -c mach -n '__mach_needs_command' -a marionette -d "Remote control protocol to Gecko, used for functional UI tests and browser automation."
complete -c mach -n '__mach_needs_command' -a marionette-test -d "Remote control protocol to Gecko, used for functional UI tests and browser automation."
complete -xc mach -n '__mach_needs_command' -a mdn -d "Search for something on MDN."
complete -c mach -n '__mach_needs_command' -a mercurial-setup -d "Help configure Mercurial for optimal development."
complete -c mach -n '__mach_needs_command' -a mochitest -d "Run any flavor of mochitest (integration test)."
complete -c mach -n '__mach_needs_command' -a mozbuild-reference -d "View reference documentation on mozbuild files."
complete -c mach -n '__mach_needs_command' -a mozharness -d "Run tests using mozharness."
complete -c mach -n '__mach_needs_command' -a mozregression -d "Regression range finder for nightly and inbound builds."
complete -c mach -n '__mach_needs_command' -a package -d "Package the built product for distribution as an APK, DMG, etc."
complete -c mach -n '__mach_needs_command' -a pastebin -d "Command line interface to pastebin.mozilla.org."
complete -c mach -n '__mach_needs_command' -a power -d "Get system power consumption and related measurements (macOS 10.10+ only)"
complete -c mach -n '__mach_needs_command' -a python -d "Run Python."
complete -c mach -n '__mach_needs_command' -a python-test -d "Run Python unit tests with an appropriate test runner."
complete -c mach -n '__mach_needs_command' -a reftest -d "Run reftests (layout and graphics correctness)."
complete -c mach -n '__mach_needs_command' -a release-history -d "Query balrog for release history used by enable partials generation."
complete -c mach -n '__mach_needs_command' -a repackage -d "Repackage artifacts into different formats."
complete -c mach -n '__mach_needs_command' -a resource-usage -d "Show information about system resource usage for a build."
complete -c mach -n '__mach_needs_command' -a robocop -d "Run a Robocop test."
complete -c mach -n '__mach_needs_command' -a run -d "Run the compiled program, possibly under a debugger or DMD."
complete -xc mach -n '__mach_needs_command' -a search -d "Search for something on the Internets."
complete -fc mach -n '__mach_needs_command' -a settings -d "Show available config settings."
complete -c mach -n '__mach_needs_command' -a show-log -d "Display mach logs."
complete -c mach -n '__mach_needs_command' -a static-analysis -d "Run C++ static analysis checks."
complete -c mach -n '__mach_needs_command' -a talos-test -d "Run talos tests (performance testing)."
complete -c mach -n '__mach_needs_command' -a taskcluster-build-image -d "Build a Docker image."
complete -c mach -n '__mach_needs_command' -a taskcluster-load-image -d "Load a pre-built Docker image."
complete -c mach -n '__mach_needs_command' -a taskgraph -d "Manipulate TaskCluster task graphs defined in-tree."
complete -xc mach -n '__mach_needs_command' -a try -d "Push selected tests to the try server."
complete -c mach -n '__mach_needs_command' -a test -d "Run tests (detects the kind of test and runs it)."
complete -c mach -n '__mach_needs_command' -a test-info -d "Display historical test result summary."
complete -fc mach -n '__mach_needs_command' -a uuid -d "Generate a uuid."
complete -c mach -n '__mach_needs_command' -a valgrind-test
complete -c mach -n '__mach_needs_command' -a vendor -d "Vendor third-party dependencies into the source repository."
complete -c mach -n '__mach_needs_command' -a warnings-list -d "Show a list of compiler warnings."
complete -c mach -n '__mach_needs_command' -a warnings-summary -d "Show a summary of compiler warnings."
complete -c mach -n '__mach_needs_command' -a watch -d "Watch and re-build the tree."
complete -c mach -n '__mach_needs_command' -a web-platform-tests
complete -c mach -n '__mach_needs_command' -a web-platform-tests-create
complete -c mach -n '__mach_needs_command' -a web-platform-tests-reduce
complete -c mach -n '__mach_needs_command' -a web-platform-tests-update
complete -c mach -n '__mach_needs_command' -a webidl-example -d "Generate example files for a WebIDL interface."
complete -c mach -n '__mach_needs_command' -a webidl-parser-test -d "Run WebIDL tests (Interface Browser parser)."
complete -c mach -n '__mach_needs_command' -a webrtc-gtest -d "Run WebRTC.org GTest unit tests."
complete -c mach -n '__mach_needs_command' -a wpt -d "Alias for web-platform-tests."
complete -c mach -n '__mach_needs_command' -a wpt-create -d "Alias for web-platform-tests-create."
complete -c mach -n '__mach_needs_command' -a wpt-manifest-update  -d "Alias for web-platform-tests-manifest-update."
complete -c mach -n '__mach_needs_command' -a wpt-reduce -d "Alias for web-platform-tests-reduce."
complete -c mach -n '__mach_needs_command' -a wpt-update -d "Alias for web-platform-tests-update."

complete -c mach -n '__mach_needs_command' -a xpcshell-test -d "Run XPCOM Shell tests (API direct unit testing)."


complete -xc mach -n '__mach_needs_command' -a android -d "Invoke android task"
complete -c mach -n '__fish_seen_subcommand_from android' -a archive-geckoview -d "Create GeckoView archives."
complete -c mach -n '__fish_seen_subcommand_from android' -a assemble-app -d "Assemble Firefox for Android."
complete -c mach -n '__fish_seen_subcommand_from android' -a checkstyle -d "Run Android checkstyle."
complete -c mach -n '__fish_seen_subcommand_from android' -a findbugs -d "Run Android findbugs."
complete -c mach -n '__fish_seen_subcommand_from android' -a geckoview-docs -d "Create GeckoView javadoc and optionally upload to Github."
complete -c mach -n '__fish_seen_subcommand_from android' -a gradle-dependencies -d "Collect Android Gradle dependencies."
complete -c mach -n '__fish_seen_subcommand_from android' -a lint -d "Run Android lint."
complete -c mach -n '__fish_seen_subcommand_from android' -a test -d "Run Android local unit tests."
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

complete -c mach -n "__fish_seen_subcommand_from xpcshell-test" -a '(__mach_complete_xpcshelltests)'

complete -c mach -n "__fish_seen_subcommand_from try" -a "fuzzy empty syntax"
complete -c mach -n "__fish_seen_subcommand_from try" -s b -xa "d o do od"
complete -c mach -n "__fish_seen_subcommand_from try" -s p -fa "(__fish_complete_list , __mach_try_print_platforms)"
complete -c mach -n "__fish_seen_subcommand_from try" -s u -fa "(__fish_complete_list , __mach_try_print_tests)"
complete -c mach -n "__fish_seen_subcommand_from try" -s t -fa "(__fish_complete_list , __mach_try_print_talos)"
complete -c mach -n "__fish_seen_subcommand_from try" -l artifact -d "Enable artifact build"
complete -c mach -n "__fish_seen_subcommand_from try" -l no-artifact -d "Disable artifact build"
complete -c mach -n "__fish_seen_subcommand_from try" -a "mozharness:\ --geckoProfile" -d "enable profiling"

complete -c mach -n "__fish_seen_subcommand_from build" -a "faster binaries"

