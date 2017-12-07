

function __fxa_authpw -S -a email pass
  set -l gen_authpw_js '((email, pass) => {
    let qs = crypto.pbkdf2Sync(pass, "identity.mozilla.com/picl/v1/quickStretch:"+email, 1000, 32, "sha256");
    return crypto.createHmac("sha256", crypto.createHmac("sha256", new Buffer(8 * 4)).update(qs).digest())
      .update("identity.mozilla.com/picl/v1/authPW\\x01").digest().toString("hex");
    })(process.argv[1], process.argv[2])'
  node -r crypto -pe $gen_authpw_js $email $pass
end

function fxacct -a action email password stack
  if test -z "$stack"
    set stack "prod"
  end
  set fxa_server

  switch $stack
  case prod
    # set fxa_server "https://accounts.firefox.com"
    set fxa_server "https://api.accounts.firefox.com"
  case stage
    # set fxa_server "https://accounts.stage.mozaws.net"
    set fxa_server "https://api-accounts.stage.mozaws.net"
  case dev
    # set fxa_server "https://stable.dev.lcip.org"
    set fxa_server "https://stable.dev.lcip.org/auth"
  case '*'
    echo "Usage: fxacct create|destroy email password [stage|dev|prod = prod]"
    return 1
  end

  echo "$stack = $fxa_server"
  switch $action
  case create destroy
    set -l authpw (__fxa_authpw $email $password)
    set -l json "{\"email\":\"$email\",\"authPW\":\"$authpw\",\"preVerified\": true}"
    set -l uri "$fxa_server/v1/account/$action"
    curl -H "Content-Type: application/json" -X POST -d $json $uri
  case '*'
    echo "Usage: fxacct create|destroy email password [stage|dev|prod = prod]"
    return 1
  end
end

