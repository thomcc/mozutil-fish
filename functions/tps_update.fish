
function tps_update
  echo "Updating or installing TPS venv at $HOME/.tps/venv"
  mkdir -p $HOME/.tps
  if test -d $HOME/.tps/last-venv
    rm -rf $HOME/.tps/last-venv
  end
  if test -d $HOME/.tps/venv
    echo "Previous installation moved to $HOME/.tps/last-venv"
    mv $HOME/.tps/venv $HOME/.tps/last-venv
  end
  pushd (gecko_root)/testing/tps
  echo "..."
  ./create_venv.py $HOME/.tps/venv > /dev/null
  popd
  echo "Successfully updated."
end
