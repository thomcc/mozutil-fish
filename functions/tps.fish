
function __tps_usage
  echo "usage: tps [command] [options] TEST"
  echo "  Makes running tps easier."
  echo ""
  echo "commands:"
  echo "  tps help           Print this message"
  echo "  tps run [TEST]     (default) run a test by name, or `all` for all tests"
  echo "  tps setup          Install a new venv, setup configs, and create test accounts"
  echo "  tps update         Update the TPS venv then exit"
  echo ""
  echo "options:"
  echo "  --help, -h         print this message and exit"
  echo "  --windowed, -w     don't run in headless mode (opens many windows)"
  echo "  --binary, -b PATH  specify binary (defaults to auto)"
  echo "  --update, -u       update the tps venv even if it seems unnecessary"
  echo "  --no-update, -n    don't bother checking if we should update the tps venv"
  echo "  --config, -c CONF  use the specified config (prod|dev|stage = prod)"
  echo "  --stage, -S        equivalent to --config stage"
  echo "  --dev, -D          equivalent to --config dev"
  echo "  --prod, -P         equivalent to --config prod"
  echo "  --raw, -r          Don't perform any processing of the log"
  echo "  --only-used, -i    Skip engines not being tested (--ignore-unused-engines)"
  echo ""
end

function __tps_update
  echo "Updating or installing TPS venv at $HOME/.tps/venv"
  mkdir -p $HOME/.tps
  if test -d $HOME/.tps/last-venv
    rm -rf $HOME/.tps/last-venv
  end
  if test -d $HOME/.tps/venv
    echo "Previous installation moved to $HOME/.tps/last-venv"
    mv $HOME/.tps/venv $HOME/.tps/last-venv
  end
  pushd (gecko_root)/testing/tps
  echo "..."
  ./create_venv.py $HOME/.tps/venv > /dev/null
  popd
  echo "Successfully updated."
end


function __tps_setup
  mkdir -p $HOME/.tps
  __tps_update
  or return 1

  get --prompt "restmail email:" | read -l email
  if test -z "$email"
    echo "No email provided, aborting"
    return 1
  end

  get --prompt "password:" | read -l password
  if test -z "$password"
    echo "No password provided, aborting"
    return 1
  end

  get --prompt "create new accounts on dev/stage/prod? [Yn]" | read -l create

  if test $create != 'n'; and test $create != 'N'
    echo "Creating account on production"
    fxacct create $email $password prod

    echo "Creating account on stage"
    fxacct create $email $password stage

    echo "Creating account on dev"
    fxacct create $email $password dev
  end

  echo "Creating prod.json, stage.json, dev.json config files"
  set -l jsonupdate ".fx_account = {\"username\":\"$email\",\"password\":\"$password\"}"
  set -l config (cat $HOME/.tps/venv/config.json | jq $jsonupdate)
  jq $jsonupdate $HOME/.tps/venv/config.json > $HOME/.tps/prod.json

  set -l set_stage '.preferences["identity.fxaccounts.autoconfig.uri"] = "https://accounts.stage.mozaws.net"'
  set -l set_dev '.preferences["identity.fxaccounts.autoconfig.uri"] = "https://stable.dev.lcip.org"'

  jq $set_stage $HOME/.tps/prod.json > $HOME/.tps/stage.json
  jq $set_dev $HOME/.tps/prod.json > $HOME/.tps/dev.json
end


function tps
  set -l just_setup
  if not test -d $HOME/.tps/venv
    echo "Performing first time setup"
    __tps_setup
    set just_setup 1
  end

  set -l config prod
  set -l binary auto
  set -l testfile
  set -l update auto

  switch $argv[1]
  case help
    __tps_usage
    return
  case update
    __tps_update
    return
  case setup
    if test -n "$just_setup"
      return
    end
    __tps_setup
    return
  case run
    set argv $argv[2..-1]
  end

  argparse --name tps -x 'c,S,D,P' -x 'n,u' -N 0 -X 1 'h/help' 'w/windowed' \
    'b/binary=' 'n/no-update' 'u/update' 'c/config=' 'S/stage' 'D/dev' \
    'P/prod' 'r/raw' 'i/only-used' -- $argv
  or begin
    __tps_usage
    return 1
  end

  if set -q _flag_help
    __tps_usage
    return
  end

  set -l ignore_unused ''
  if set -q _flag_i
    set ignore_unused '--ignore-unused-engines'
  end

  set -lx MOZ_HEADLESS 1
  if set -q _flag_w
    set -e MOZ_HEADLESS
  end

  set config prod
  if set -q _flag_config
    set config $_flag_config
  else if set -q _flag_stage
    set config stage
  else if set -q _flag_prod
    set config prod
  else if set -q _flag_dev
    set config dev
  end

  set -l test_root (gecko_root)/services/sync/tests/tps

  set -l testfile $argv[1]
  if test -z "$testfile"
    echo "Expected a file argument!"
    __tps_usage
    return
  end

  if test $testfile != 'all'; and not test -f $test_root/$testfile
    echo "tps: Test file '$testfile' doesn't look like a valid test file (or 'all')..."
    return
  end

  pushd (gecko_root)

  if set -q _flag_update
    __tps_update
  else if not set -q _flag_n
    if test (stat -f "%m" $HOME/.tps/venv) -lt (git log -n 1 --pretty=format:%at -- (gecko_root)/testing/tps)
      echo "Commits made into TPS dir, updating ~/.tps/venv in 5s"
      sleep 5
      __tps_update
    end
  end

  set -l binary

  if not set -q _flag_binary; or test "$_flag_binary" = 'auto'
    set -l objdir (mach environment --format=json | jq -r '.topobjdir')
    if not test -f $objdir/config.status
      echo "Warning: No binary provided and we don't seem to be built yet. Trying anyway"
    end

    set -l binscript 'import mozbuild.base; print(mozbuild.base.MozbuildObject.from_environment().get_binary_path("app"))'
    set binary (echo $binscript | mach python 2> /dev/null)
    if test -z "$binary"; or not test -f "$binary"
      echo "Error: unable to locate firefox binary! Do you need to do a build?"
      return 1
    end
  else
    if not test -f $_flag_binary
      echo "Error: Binary provided but doesn't seem usable..."
      return 1
    end
  end
  echo "Running TPS using binary $binary"

  source $HOME/.tps/venv/bin/activate.fish

  set -l tps_args $ignore_unused --debug --binary $binary --configfile $HOME/.tps/$config.json

  set -l multiple_tests
  if test "$testfile" = "all"
    set multiple_tests 1
    set testfile all_tests.json
  else
    set tps_args $tps_args --testfile $testfile
    if string match -qir '\*\.json$' $testfile
      set multiple_tests 1
    end
  end
  if set -q _flag_raw
    runtps $tps_args
  else
    set -l have_colors
    if isatty
      set have_colors 1
      function __tps_setcolor
        set_color $argv
      end
    else
      function __tps_setcolor
        echo ''
      end
    end
    # all the code beyond here is concerned with making the logs colored,
    # and more easily digestable.
    set -l all_colors green yellow blue magenta cyan \
        brgreen bryellow brblue brmagenta brcyan
    set -l color_idx 1

    set -l logger_colors '{}'
    set -l cur_test
    set -l cur_phase '(setup)'
    set -l cur_phase_json '{}'
    set -l cur_profile '{}'
    set -l cur_action
    set -l log_prefix ''
    set -l num_tests 1
    set -l test_idx 0
    set -l phase_idx 0
    set -l num_phases 0
    set -l test_msg ''
    set -l phase_msg ''
    set -l num_profiles 0
    set -l clean_idx 0
    set -l testpad ''
    set -l prefix ''
    # set -l phase_start_time 0
    if test -n "$multiple_tests"
      set num_tests (cat $test_root/$testfile | jq -r '.tests | length' 2> /dev/null)
      if test -z "$num_tests"; or test $num_tests -eq 0
        set num_tests 0
      end
    end
    runtps $tps_args | while read -l line
      # check for test start
      if set maybe_test (string match -r '^Running test (.*)$' -- $line);
        set curtest $maybe_test[2]
        set fullpath $test_root/$curtest
        set cur_phase '(setup)'
        set phase_idx 0
        set num_phases 0
        set clean_idx 0
        # set phase_start_time 0
        set cur_action 0
        if test -f "$fullpath"
          set cur_phase_json (cat $fullpath | string join ' ' | string replace -r '^[^\}]+\{(.+?)\}.*$' '{$1}' | jq '.' -c 2> /dev/null)
          set num_phases (echo $cur_phase_json | jq -r 'keys | length' 2> /dev/null)
          set num_profiles (echo $cur_phase_json | jq -r 'to_entries | map(.value) | unique | length' 2> /dev/null)
          if test -z "$num_phases"
            set num_phases 0
          end
          if test -z "$num_profiles"
            set num_profiles 0
          end
        else
          # oh dear
          set cur_phase_json '{}'
        end
        set test_idx (math 1+$test_idx)

        echo -s (__tps_setcolor bryellow --bold) $line (__tps_setcolor normal)

        set test_msg (echo -sn \
          (__tps_setcolor cyan) $curtest (__tps_setcolor normal))
        if test -n "$multiple_tests"
          set testpad '  '
          set test_msg (echo -sn $test_msg ':' \
            (__tps_setcolor blue) $test_idx (__tps_setcolor normal) '/' \
            (__tps_setcolor blue) $num_tests (__tps_setcolor normal))
        end
        set prefix "  [$test_msg] "
        continue
      end

      if string match -qr "^CROSSWEAVE" -- $line
        # check for phase start
        if set maybe_phase (string match -r '^CROSSWEAVE INFO: Starting phase (.*)$' -- $line)
          set cur_phase $maybe_phase[2]
          set cur_action ''
          # set phase_start_time 0
          set phase_idx (math 1 + $phase_idx)
          if string match -qr '^cleanup-' $cur_phase
            set clean_idx (math 1 + $clean_idx)
            # pretend we dont know, so that we don't say [cleanup-profile1](profile1)
            set cur_profile ''
            set phase_msg (echo -sn '|' (__tps_setcolor blue) "cleanup$clean_idx" (__tps_setcolor normal) '/' \
              (__tps_setcolor blue) $num_profiles (__tps_setcolor normal))
          else
            set cur_profile (echo $cur_phase_json | jq -r ".$cur_phase" 2> /dev/null)
            if test "$cur_profile" = 'null'
              set cur_profile ''
            end
            set phase_msg (echo -sn '|' (__tps_setcolor brblue) "phase$phase_idx" (__tps_setcolor normal) '/' \
              (__tps_setcolor blue) $num_phases (__tps_setcolor normal))
            if test -n "$cur_profile"
              set phase_msg (echo -sn $phase_msg '@' (__tps_setcolor cyan) $cur_profile (__tps_setcolor normal))
            end
          end
          set prefix "    [$test_msg$phase_msg] "
          echo -s $prefix (__tps_setcolor yellow) $line (__tps_setcolor normal)
          continue
        end

        if set maybe_action (string match -r '^CROSSWEAVE INFO: starting action:\s(.*)$' -- $line)
          set cur_action $maybe_action[2]
          set prefix "    [$test_msg$phase_msg]{$cur_action} "
          echo -s $prefix (__tps_setcolor yellow) $line (__tps_setcolor normal)
          set prefix "  $prefix"
          continue
        end

        if string match -qr '^CROSSWEAVE TEST PASS' -- $line
          set prefix "    [$test_msg$phase_msg]"
          if test -n "$cur_action"
            echo -s $prefix "{$cur_action} " (__tps_setcolor green) $line (__tps_setcolor normal)
          end
          set prefix "$prefix "
          set cur_action ''
          continue
        end

        if string match -qr '^CROSSWEAVE ERROR' -- $line
          set prefix "    [$test_msg$phase_msg]"
          if test -n "$cur_action"
            echo -s $prefix "{$cur_action} " (__tps_setcolor red) $line (__tps_setcolor normal)
          end
          set prefix "$prefix "
          set cur_action ''
          continue
        end
        echo -s $prefix (__tps_setcolor yellow) $line (__tps_setcolor normal)
        continue
      end
      # date Sync.Blah.Blah INFO blah blah bla...
      if set synclogline (string match -r '^(\d+)\s+(\S+)\s+([A-Z]{4,6})\s*(.*)$' -- $line)
        # TODO: make the date more useful...
        set levelcolor bryellow
        switch $synclogline[4]
        case FATAL ERROR
          set levelcolor brred
        case WARN
          set levelcolor bryellow
        case INFO CONFIG
          set levelcolor yellow
        case DEBUG TRACE
          set levelcolor cyan
        end
        set src_color (echo $logger_colors | jq -er '.[$eng]' --arg eng $synclogline[3])
        if test "$src_color" = 'null'; or test -z "$src_color"
          if test "$color_idx" -lt (count $all_colors)
            set src_color $all_colors[$color_idx]
            set color_idx (math 1 + $color_idx)
          else
            set -l c0 (random choice 3 4 5 6 7 8 9 a b)
            set -l c1 (random choice 6 7 8 9 a b c e f)
            set -l c2 (random choice 1 2 3 4 5 6 7 8 9)
            # avoid permutations where it's mostly red...
            set src_color (random choice "$c0$c1$c2" "$c1$c2$c0" "$c1$c0$c2" "$c0$c2$c1")
          end
          set logger_colors (echo $logger_colors | \
            jq -er '.[$e] |= $c' --arg e $synclogline[3] --arg c $src_color)
        end
        echo -s $prefix \
          (__tps_setcolor 844) $synclogline[2] (__tps_setcolor normal) ' ' \
          (__tps_setcolor $src_color) $synclogline[3] (__tps_setcolor normal) ' ' \
          (__tps_setcolor $levelcolor --bold) $synclogline[4] (__tps_setcolor normal) ' ' \
          $synclogline[5]

        #if test -n "$have_colors"; and set maybejson (string match -r '^([^\{]+): (\{.*\}|\[.*\])\s*$' -- $synclogline[5])
        #  set pretty_json (echo $maybejson[3] | jq '.' -ceC ^ /dev/null)
        #  if test "$pretty_json" != 'null'; and test -n "$pretty_json"
        #    echo -s "$maybe_json[2]: " $pretty_json
        #    continue
        #  end
        #end
        # echo $synclogline[5]
        continue
      end
      if string match -qir '^TEST\-UNEXPECTED\-FAIL|^\s*(phase|cleanup-).*FAIL' -- $line
        echo -s $prefix (__tps_setcolor red) $line (__tps_setcolor normal)
      else if string match -qir '^TEST\-PASS|^\s*(phase|cleanup-).*PASS' -- $line
        echo -s $prefix (__tps_setcolor green) $line (__tps_setcolor normal)
      else if string match -qir '^\s*(phase|cleanup-).*unknown' -- $line
        echo -s $prefix (__tps_setcolor brmagenta) $line (__tps_setcolor normal)
      else if string match -qir '^(Test Summary)' -- $line
        echo -s $prefix $line
      else
        echo -s $prefix (__tps_setcolor 686868) $line (__tps_setcolor normal)
      end
    end
  end

  popd
  deactivate
end
