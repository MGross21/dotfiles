{ runCommand, src }:
runCommand "omarchy-shell-compat" { } ''
  mkdir $out
  cp -r ${src}/shell/Ui ${src}/shell/Commons $out
  chmod -R u+w $out
  cp ${./Color.qml} $out/Commons/Color.qml
  substituteInPlace $out/Ui/KeyboardPanel.qml --replace-fail \
    '    x = Math.max(margin, Math.min(x, screenW - contentWidth - margin))' \
    '    if (bar.section === "left") x = anchorScreenPos.x
      else if (bar.section === "right") x = anchorScreenPos.x + anchorW - contentWidth
      else if (bar.section === "center") x = screenW / 2 - contentWidth / 2
      x = Math.max(margin, Math.min(x, screenW - contentWidth - margin))'
''
