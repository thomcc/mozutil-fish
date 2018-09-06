
function __fxacct_authpw -S -a email pass
  set -l gen_authpw_js '((email, pass) => {
    let qs = crypto.pbkdf2Sync(pass, "identity.mozilla.com/picl/v1/quickStretch:"+email, 1000, 32, "sha256");
    return crypto.createHmac("sha256", crypto.createHmac("sha256", Buffer.alloc(8 * 4)).update(qs).digest())
      .update("identity.mozilla.com/picl/v1/authPW\\x01").digest().toString("hex");
    })(process.argv[1], process.argv[2])'
  node -r crypto -pe $gen_authpw_js $email $pass
end

function __fxacct_usage
  echo "Usage: fxacct action username password [stack]"
  echo ""
  echo "Create or destroy firefox accounts across various stacks."
  echo ""
  echo "Parameters:"
  echo "  action          Either 'create' or 'destroy'"
  echo "  username        Email or restmail username. Restmail emails will be autoverified."
  echo "  password        Account password."
  echo "  stack           One of prod, stage, dev, or a URL, defaults to prod."
  echo "                  (URLs are expected to begin with 'http://' or 'https://')"
  echo ""
  echo "Note: This tool expects `jq` and `node` to be in the PATH"
end

function fxacct -a action email password stack

  if test (count $argv) -lt 3
    __fxacct_usage
    return 1
  end

  if not type -q jq;
    echo "Error: No jq command found in the path. Required."
    return 1
  end

  if not type -q node
    echo "Error: no node command found in the path. Required."
    return 1
  end

  if test -z "$stack"
    set stack "prod"
  end

  set fxa_server
  set restmail_user
  if string match -qr '@restmail\.net$' $email
    set restmail_user (string replace -r '@restmail\.net$' '' $email)
  else if test $action = "create"
    echo "Warning: creating a non-restmail account. Won't be able to autoverify"
  end

  switch $stack
  case prod
    set fxa_server "https://api.accounts.firefox.com"
  case stage
    set fxa_server "https://api-accounts.stage.mozaws.net"
  case dev
    set fxa_server "https://stable.dev.lcip.org/auth"
  case 'https://*' 'http://*'
    # Check if the wrong server was passed in
    if set config (curl -sfS "$stack/.well-known/fxa-client-configuration" 2>/dev/null)
      set fxa_server (echo $config | jq -r '.auth_server_base_url')
    end
    if test -z "$fxa_server"
      set fxa_server $stack
    end
  case '*'
    echo "Unknown stack $stack"
    __fxacct_usage
    return 1
  end

  echo "Using API server: $fxa_server"

  switch $action
  case create destroy
    set -l authpw (__fxacct_authpw $email $password)
    # @@TODO: how does preVerified work???
    set -l json "{\"email\":\"$email\",\"authPW\":\"$authpw\"}"
    set -l uri "$fxa_server/v1/account/$action"
    if test $action = 'create'; and test -n "$restmail_user"
      echo "Clearing restmailbox before autoverifying"
      curl -sX DELETE "https://restmail.net/mail/$restmail_user"
    end
    # echo "POSTing '$json' to $uri"
    if test $action = "create"
      echo "Creating account..."
    else
      echo "Destroying account..."
    end
    set -l result (curl -sS -H "Content-Type: application/json" -X POST -d $json $uri)
    if test $status -ne 0; or test -z "$result"; or test (echo $result | jq '.code') != 'null'
      echo "Server responded with an error!"
      if test -n "$result"
        echo $result | jq -C ''
      end
      return 1
    end

    if test $action != 'create';
      echo "Account $email successfully destroyed!"
      return 0
    end
    if test -z "$restmail_user"
      echo "Success! Check your email at '$email' to verify your account"
      return 0
    end
    echo "Success! Attempting to autoverify for restmail user $restmail_user"
    set -l uid (echo $result | jq -r '.uid')
    sleep 2
    set -l code
    for i in (seq 1 5)
      echo "Fetching restmailbox ..."

      if not set mail (curl -sSLf "https://restmail.net/mail/$restmail_user")
        echo "Error: Failed to get mail for '$restmail_user'!"
        if test -n "$mail"
          echo "Response: $mail"
        end
        return 1
      end

      set code (echo $mail | jq -r --arg uid $uid '.[] |
        select(.headers["x-uid"] == $uid and
               .headers["x-template-name"] == "verifyEmail") |
        .headers["x-verify-code"]')

      if test -n "$code"; and test "$code" != "null"
        echo "Got verification code! $code"
        break
      end

      if test $i -ne 5
        set -l dur (math "$i*5")
        echo "Nothing yet. Retrying $i of 4 after waiting $dur seconds."
        for j in (seq 1 $dur)
          sleep 1
          echo -n '.'
        end
        echo ''
      end
    end

    if test -z "$code"
      echo "Error: Failed to get verification code, manual verification needed. Restmail contents follow"
      echo $mail | jq -C ''
      return 1
    end

    set verify_uri "$fxa_server/v1/recovery_email/verify_code"
    set json "{\"uid\":\"$uid\",\"code\":\"$code\"}"

    # echo "POSTing '$json' to $verify_uri"
    if set result (curl -sSf -H "Content-Type: application/json" -X POST -d $json $verify_uri)
      echo "Success! Account with email '$email' and password '$password' is verified!"
    else
      echo "Server responded with an error!"
      if test -n "$result"
        echo $result | jq -C ''
      end
      return 1
    end

  case '*'
    echo "fxacct: Unknown action"
    __fxacct_usage
    return 1
  end
end

