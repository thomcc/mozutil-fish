
function __tps_usage
  echo "usage: tps [options] TEST"
  echo "  Makes running tps easier. see also tps_update and tps_setup"
  echo ""
  echo "TEST may be be one of the test files or the string 'all'"
  echo "options:"
  echo "  --help, -h         print this and exit"
  echo "  --no-headless      don't run in headless mode"
  echo "  --binary, -b PATH  specify binary (defaults to auto)"
  echo "  --update, -u       update the tps venv even if it seems unnecessary"
  echo "  --no-update        don't bother checking if we should update the tps venv"
  echo "  --config, -c CONF  use the specified config (prod|dev|stage = prod)"
  echo "  --stage, -S        equivalent to --config stage"
  echo "  --dev, -D          equivalent to --config dev"
  echo "  --prod, -P         equivalent to --config prod"
  echo ""
end

function tps

  set -xl MOZ_HEADLESS 1

  set -l config prod
  set -l binary auto
  set -l testfile
  set -l update auto

  getopts $argv | while read -l key value
    switch $key

      case h help
        __tps_usage
        return 0

      case no-headless
        set -e MOZ_HEADLESS

      case c config
        set config $value

      case P prod
        set config prod

      case S stage
        set config stage

      case D dev
        set config dev

      case b binary
        set binary $value

      case u update
        set update "always"

      case no-update
        set update "no"

      case _
        switch $value
          case all '*.js' '*.json'
            set testfile $value
          case '*'
            __tps_usage
            return 1
        end
    end
  end

  if test -z "$testfile"
    __tps_usage
    return 1
  end

  pushd (gecko_root)

  if test $update = "always"
    tps_update
  else if test $update = "auto"
    if test (stat -f "%m" $HOME/.tps/venv) -lt (git log -n 1 --pretty=format:%at -- (gecko_root)/testing/tps)
      echo "Commits made into TPS dir, updating ~/.tps/venv in 5s"
      sleep 5
      tps_update
    end
  end


  if test "$binary" = "auto";
    set objdir (mach environment --format=json | jq -r '.topobjdir')
    if not test -f $objdir/config.status
      echo "Warning: No binary provided and we don't seem to be built yet. Trying anyway"
    end

    set -l binscript 'import mozbuild.base; print(mozbuild.base.MozbuildObject.from_environment().get_binary_path("app"))'
    set binary (echo $binscript | mach python 2> /dev/null)
    if test -z "$binary"; or not test -f "$binary"
      echo "Error: unable to locate firefox binary! Do you need to do a build?"
      return 1
    end
  end
  echo "Running TPS using binary $binary"

  source $HOME/.tps/venv/bin/activate.fish

  if test $testfile = "all"
    runtps --debug --binary $binary --configfile $HOME/.tps/$config.json
  else
    runtps --debug --binary $binary --configfile $HOME/.tps/$config.json --testfile $argv[1]
  end
  popd
  deactivate
end
