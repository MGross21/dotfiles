{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kimun";
  version = "0.24.2";

  src = fetchFromGitHub {
    owner = "nico2sh";
    repo = "kimun";
    tag = "kimun-notes-v${finalAttrs.version}";
    hash = "sha256-MeLrKsn7MMaOnTljdbhm6KSctgxzttXnEUauFGSI+5I=";
  };

  cargoHash = "sha256-1AXzLzDG/Yr6dfa08O2BfWAwnBnHJQuM73fU/an3td0=";

  cargoBuildFlags = [
    "-p"
    "kimun-notes"
  ];
  cargoTestFlags = finalAttrs.cargoBuildFlags;

  # Both are `#[should_panic]` over a `debug_assert!`, which is compiled out of
  # the release profile buildRustPackage tests in; upstream CI runs debug.
  checkFlags = [
    "--skip=components::text_editor::view::tests::splice_real_on_placeholder_is_rejected"
    "--skip=keys::tests::a_duplicate_combo_in_one_table_panics"
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "kimun-notes-v(.*)"
    ];
  };

  meta = {
    description = "Terminal-based notes application with powerful search";
    homepage = "https://github.com/nico2sh/kimun";
    license = lib.licenses.mit;
    mainProgram = "kimun";
    platforms = lib.platforms.unix;
  };
})
