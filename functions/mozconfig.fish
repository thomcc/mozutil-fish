
function __mozconfig_show
  if test -z "$MOZCONFIG"
    echo "No mozconfig activated"
  else
    echo $MOZCONFIG
  end
end

function __mozconfig_init
  mkdir -p $HOME/.mozconfigs

  if not test -f $HOME/.mozconfigs/.template
    touch $HOME/.mozconfigs/.template
    echo "mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-@CONFIG_GUESS@" >> $HOME/.mozconfigs/.template
    echo "ac_add_options --enable-application=browser" >> $HOME/.mozconfigs/.template
  end
end

function __mozconfig_new
  set -l root $HOME/.mozconfigs

  __mozconfig_init

  set -l args $argv
  set -l edit

  if test $argv[1] = '-e'
    set edit yes
    set args $argv[2..]
  end


  if not set -q args[1]
    echo "usage: mozconfig new [-e] new_config_name [template]"
    return 1
  end

  if test -e $HOME/.mozconfigs/$args[1]
    echo "error: mozconfig $args[1] already exists"
    return 1
  end

  set -l template $HOME/.mozconfigs/.template
  if set -q args[2];
    if test -e $HOME/.mozconfigs/$args[2]
      set template $HOME/.mozconfigs/$args[2]
    else if test -e $args[2]
      set template (realpath $args[2])
    else
      echo "warning: no such template or file $args[2]. using default template"
    end
  end
  cp $template $HOME/.mozconfigs/$args[1]
  if test $edit = "yes"
    __mozconfig_edit $HOME/.mozconfigs/$args[1]
  end
end

function __mozconfig_use
  set -l confpath $HOME/.mozconfigs/$argv[1]

  if not test -f $confpath
    echo "Error: $confpath does not exist"
    return 1
  end

  set -l mozconfig $confpath

  echo "$argv[1]" > $HOME/.mozconfigs/.active

  set -gx MOZCONFIG $mozconfig

  if test "$argv[2]" != '-q'
    echo $MOZCONFIG
  end
  return 0
end

function __mozconfig_edit
  set -l editor $VISUAL
  if test -z $editor
    set editor $EDITOR
  end
  if test -z $editor
    echo "Failed to open editor!"
    return 1
  end
  if not test -e $argv[1]; and test -e $HOME/.mozconfigs/$argv[1]
    eval $editor $HOME/.mozconfigs/$argv[1]
  else
    eval $editor $argv[1]
  end
end

function __mozconfig_list
  set -l active (basename $MOZCONFIG)
  for config in (command ls $HOME/.mozconfigs)
    if test $config = $active
      echo $config\*
    else
      echo $config
    end
  end
end

function __mozconfig_usage
  echo "usage: mozconfig command [args]"
  echo ""
  echo "Utility to make working with mozconfigs easier"
  echo ""
  echo "mozconfig help                   print this and exit"
  echo "mozconfig show                   print full path to current mozconfig (default if no command is provided)"
  echo "mozconfig edit [config]          edit current or provided mozconfig"
  echo "mozconfig new [-e] NAME [tmpl]   create (and edit) new mozconfig, copy from [tmpl], edit with -e"
  echo "mozconfig list                   list mozconfigs"
  echo "mozconfig use config             set current config"
end

function mozconfig -d "Utility to make working with mozconfigs easier"
  if set -q _flag_help
    return
  end

  set -l mozconfigdir $HOME/.mozconfigs
  if set -q HOME/.mozconfigs
    set mozconfigdir $HOME/.mozconfigs
  end

  # no args, print current

  if not set -q argv[1]
    set argv show
  end

  switch $argv[1]
  case help
    __mozconfig_usage

  case show
    __mozconfig_show

  case list
    __mozconfig_list

  case new
    __mozconfig_new $argv[2..-1]

  case use
    __mozconfig_use $argv[2..-1]

  case edit
    if set -q argv[2]
      __mozconfig_edit $argv[2]
    else
      __mozconfig_edit $current
    end

  case '*'
    echo "Error: unknown command $argv[1]\n"
    __mozconfig_usage
    return 1
  end

end


