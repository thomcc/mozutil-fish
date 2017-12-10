
function sf -d "Search searchfox"
  set args (string escape --style=url (string join ' ' $argv))
  open "http://searchfox.org/mozilla-central/search?q=$args"
end
