
function bz -d "Try and open bugzilla to the currently active bug (no args), or do a bugzilla search"
  if test -n "$argv"
    set me (git config --get bz.username)
    set arg (string join ' ' $argv)
    set arg (string replace -r '\-a|\ball\b' 'ALL ' $arg)
    set arg (string replace -r 'mine' "reporter:$me" $arg)
    set arg (string replace -r '\bme\b' $me $arg)
    set arg (string replace -r '\br:' 'reporter:' $arg)
    bzsearch $arg
  else if set branch (git_branch_name)
    if set match (string match -ir '(?:bug|review|rev)[^\d]*(?:(\d+)[-/])?(.*)$' $branch)
      set bugno $match[2]
    else
      set bugno (string replace -ra '[^\d]' '' $branch 2>/dev/null)
    end
    if test -z "$bugno"; and test "$branch" != 'central'
      set last_commit (git log -n1 --pretty=format:%s 2>/dev/null)
      if test -n "$last_commit"
        set matched (string match -ir '^bug (\d+) ' $last_commit)
        if set -q matched[2]
          set bugno matched[2]
        end
      end
    end
    if test -n "$bugno"
      open "https://bugzilla.mozilla.org/show_bug.cgi?id=$bugno"
    else
      open "https://bugzilla.mozilla.org"
    end
  else
    open "https://bugzilla.mozilla.org"
  end
end
