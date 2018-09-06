
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
  if test "$testfile" != "all"
    set tps_args $tps_args --testfile $testfile
  end

  # function on_tps_exit
  #   functions -e on_tps_exit
  #   echo "In TPS cleanup"
  #   popd
  #   deactivate
  # end

  if set -q _flag_raw
    runtps $tps_args
  else
    runtps $tps_args | tps_pretty_log $testfile -c
  end

  popd
  deactivate
end
