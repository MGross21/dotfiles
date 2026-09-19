{
  runCommand,
  papirus-icon-theme,
  papirus-folders,
}:
runCommand "papirus-icon-theme-red"
  {
    nativeBuildInputs = [ papirus-folders ];
  }
  ''
    tmpdir=$(mktemp -d)
    cp -r ${papirus-icon-theme}/share/icons/. $tmpdir/
    chmod -R u+w $tmpdir
    DISABLE_UPDATE_ICON_CACHE=1 papirus-folders -t $tmpdir/Papirus -C red
    DISABLE_UPDATE_ICON_CACHE=1 papirus-folders -t $tmpdir/Papirus-Dark -C red
    DISABLE_UPDATE_ICON_CACHE=1 papirus-folders -t $tmpdir/Papirus-Light -C red
    mkdir -p $out/share/icons
    cp -r $tmpdir/. $out/share/icons/
  ''
