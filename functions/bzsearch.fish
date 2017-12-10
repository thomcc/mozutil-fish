

function bzsearch -d "Quicksearch for a bug"
  set -l qs (string escape --style=url (string join ' ' $argv))
  open "https://bugzilla.mozilla.org/buglist.cgi?quicksearch=$qs"
end
