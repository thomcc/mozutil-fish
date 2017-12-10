function mdn -d "Search mdn"
  set args (string escape --style=url (string join ' ' $argv))
  open "http://mdn.io/$args"
end
