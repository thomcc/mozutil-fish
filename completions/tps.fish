
function __tps_testfiles
  echo "all"
  for file in (command ls (gecko_root -a)/services/sync/tests/tps/)
    if string match -q \*.js $file
      echo $file
    end
  end
end

# complete -xc runtps -l 'testfile' -a '(__tps_testfiles)'

complete -xc tps -a '(__tps_testfiles)'
complete -fc tps -l help -s h -d "Display help"
complete -fc tps -l no-headless -d "Don't run headlessly"
complete -xc tps -l config -s c -d "Select config" -a "stage prod dev"
complete -fc tps -l prod -s P -d "Use prod config"
complete -fc tps -l stage -s S -d "Use stage config"
complete -fc tps -l dev -s D -d "Use dev config"
complete -rc tps -l binary -s b -d "Specify path to firefox binary"
complete -fc tps -l update -s u -d "Force update venv"
complete -fc tps -l no-update -d "Don't update venv"

