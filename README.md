# mozutil-fish

utilities for working with mozilla stuff.

## install/setup

with [fisherman](https://github.com/fisherman/fisherman) run:

```
fisher thomcc/mozutil-fish
set -U GECKO /path/to/gecko
```

the tps and fxacct commands also require you to have installed `jq` and `node`. most stuff assumes you're using git to interact with mozilla-central, and not hg.

## documentation

### features

- `mozconfig`: a reimplementation of [mozconfigwrapper](https://github.com/ahal/mozconfigwrapper) that works with fish.
- `mach`: a mach wrapper with completion that works outside of your gecko repo.
- `tps`: run [tps tests](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS_Tests) with less pain (manages configs, updating, activating/deactivating venv, setting MOZ_HEADLESS, etc), and has autocompletion for the tests in the test dir.
- `fxacct`: a tool for creating and destroying firefox accounts, expecially ones with restmail email addresses. mainly intended for use with `tps`.
- `bz`: try to open bugzilla for the current bug (it assumes you name your branches like `bug/<bugno>-stuff-blah-blah`)
- `bzsearch`: quicksearch bugzilla
- `sf`: quicksearch searchfox
- `mdn`: quicksearch mdn

### commands

#### mozconfig

not materially better than [mozconfigwrapper](https://github.com/ahal/mozconfigwrapper), but works with fish

usage:

```
$ mozconfig help

usage: mozconfig command [args]

Utility to make working with mozconfigs easier.

  mozconfig help                   print this and exit
  mozconfig show                   print full path to current mozconfig
  mozconfig edit [config]          edit current or provided mozconfig
  mozconfig new [-e] NAME [tmpl]   create (and edit) new mozconfig, copy from [tmpl], edit with -e.
  mozconfig list                   list mozconfigs
  mozconfig use config             set current config

```

##### buildwith, mkmozconfig

aliases for `mozconfig use` and `mozconfig new`.

#### mach

mach wrapper for fish with autocompletion, that works (well, as much as possible) even when not in the same directory as mach.

#### gecko_root

prints the current if you're in one, otherwise prints `$GECKO`. used to implement
most of the others. two options: `-q` and `-r`. `-q` (quiet) means "return 0 if we're in a
gecko root" and `-r` (require) means "error instead of printing $GECKO if we aren't in one".


#### tps

helper to run [tps](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/TPS_Tests) tests. see also [`tps_setup`](#tps_setup), [`tps_update`](#tps_update).

notes:

- run tps_setup first.
- offers autocompletion for test filenames!
- runs tps headlessly unless you pass --no-headless.
- automatically updates your tps venv if there have been commits to testing/tps since you last updated it.
- automatically activates and deactivates the tps venv for you

```
$ tps test_sync.js
<runs tps against test_sync.js on prod>

$ tps -S all
<runs tps against all tests on stage>

$ tps -h
usage: tps [command] [options] TEST
  Makes running tps easier.

commands:
  tps help           Print this message
  tps run [TEST]     (default) run a test by name, or `all` for all tests
  tps setup          Install a new venv, setup configs, and create test accounts
  tps update         Update the TPS venv then exit

options:
  --help, -h         print this message and exit
  --no-headless, -H  don't run in headless mode
  --binary, -b PATH  specify binary (defaults to auto)
  --update, -u       update the tps venv even if it seems unnecessary
  --no-update, -n    don't bother checking if we should update the tps venv
  --config, -c CONF  use the specified config (prod|dev|stage = prod)
  --stage, -S        equivalent to --config stage
  --dev, -D          equivalent to --config dev
  --prod, -P         equivalent to --config prod
  --raw, -r          Don't do any formatting of the logfile (by default it will
                     try to make things clearer)
```

#### fxacct

create and delete fxaccounts locally. accounts on restmail restmail required by tps, but who knows.

```
$ fxacct create 'foobar@restmail.net' 'hunter2'
<creates an account on prod and autoverifies it since it's a resmail account>
$ fxacct destroy 'foobar@restmail.net' 'hunter2'
<cleans up after previous command>
$ fxacct create 'my-tps-acct@baz.quux' 'p455w0rd' stage
<creates an account on stage>
$ fxacct create 'stuff@stuff.example' 'qwerty' dev
<creates an account on dev>
```
