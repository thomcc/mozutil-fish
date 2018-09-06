
function tps_pretty_log
  argparse --name tps_pretty_log -x 'c,n' -N 0 -X 1 'c/color' 'n/no-color' -- $argv
  set -l testfile $argv[1]
  set -l test_root (gecko_root)/services/sync/tests/tps
  set -l multiple_tests
  if test -n "$testfile"
    set multiple_tests 1
  else if test "$testfile" = "all"
    set multiple_tests 1
    set testfile all_tests.json
  else
    set tps_args $tps_args --testfile $testfile
    if string match -qir '\*\.json$' $testfile
      set multiple_tests 1
    end
  end
  set -l have_colors

  if isatty; and not set -q _flag_n
    set have_colors 1
  else if set -q _flag_c
    set have_colors 1
  end

  if test "$have_colors" = "1"
    function __tps_setcolor
      set_color $argv
    end
  else
    function __tps_setcolor
      echo ''
    end
  end

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

  if test -n "$multiple_tests"; and test -n "$testfile"
    set num_tests (cat $test_root/$testfile | jq -r '.tests | length' 2> /dev/null)
    if test -z "$num_tests"; or test $num_tests -eq 0
      set num_tests 0
    end
  end

  while read -l line
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
