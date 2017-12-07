
function tps_setup
  mkdir -p $HOME/.tps
  tps_update

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
