{ pkgs, ... }:
let
	wine = pkgs.wineWow64Packages.stable;
	wineMono = pkgs.fetchurl {
		url = "https://dl.winehq.org/wine/wine-mono/11.0.0/wine-mono-11.0.0-x86.msi";
		hash = "sha256-1+/t4Lm9z1ITT4zWztWdn+zpdvcLEaQAvbR7hkVpzSc=";
	};

	robotstudio = pkgs.writeShellScriptBin "robotstudio" ''
		set -euo pipefail

		export WINEARCH=win64
		export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/wine/abb-robotstudio"
		export WINEDLLOVERRIDES="mscoree,mshtml="
		export WINEESYNC=1
		export WINEFSYNC=1

		installer_url="https://www.abb.com/global/en/areas/robotics/products/software/robotstudio-suite"
		installer_dir="''${XDG_DOWNLOAD_DIR:-$HOME/Downloads}/RobotStudio"
		installer=""

		resolve_installer() {
			local target="''${1:-$installer_dir}"

			if [[ -d "$target" ]]; then
				if [[ -f "$target/setup.exe" ]]; then
					printf '%s\n' "$target/setup.exe"
					return 0
				fi

				local msi
				msi="$(find "$target" -maxdepth 1 -type f -iname '*.msi' | sort | head -n 1 || true)"
				if [[ -n "$msi" ]]; then
					printf '%s\n' "$msi"
					return 0
				fi
			fi

			if [[ -f "$target" ]]; then
				printf '%s\n' "$target"
				return 0
			fi

			return 1
		}

		mkdir -p "$WINEPREFIX"
		if [[ ! -f "$WINEPREFIX/system.reg" ]]; then
			"${wine}/bin/wineboot" -u
			"${wine}/bin/winecfg" -v win10 >/dev/null 2>&1 || true
		fi

		"${wine}/bin/wine" reg add "HKCU\\Control Panel\\Desktop" /v LogPixels /t REG_DWORD /d 144 /f >/dev/null 2>&1 || true
		"${wine}/bin/wine" reg add "HKCU\\Control Panel\\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >/dev/null 2>&1 || true

		if [[ ! -f "$WINEPREFIX/.robotstudio-prepared" ]]; then
			"${wine}/bin/wine" msiexec /i ${wineMono}
			"${robotstudioWinetricks}/bin/robotstudio-winetricks"
			touch "$WINEPREFIX/.robotstudio-prepared"
		fi

		if [[ "''${1:-}" == "--install" ]]; then
			installer="$(resolve_installer "''${2:-}")" || true

			if [[ -z "$installer" ]]; then
				echo "RobotStudio installer not found in: ''${2:-$installer_dir}"
				echo "Download it from: $installer_url"
				exit 1
			fi

			case "$installer" in
				*.msi)
					exec "${wine}/bin/wine" msiexec /i "$installer"
					;;
				*.exe)
					exec "${wine}/bin/wine" "$installer"
					;;
				*)
					echo "Unsupported installer: $installer"
					exit 1
					;;
			esac
		fi

		exe_path="$(find "$WINEPREFIX/drive_c" -type f \( -iname 'RobotStudio.exe' -o -iname 'RobotStudio64.exe' \) 2>/dev/null | head -n 1 || true)"

		if [[ -z "$exe_path" ]]; then
			echo "RobotStudio executable not found in $WINEPREFIX"
			echo "Run: robotstudio --install"
			echo "Installer source: $installer_url"
			exit 1
		fi

		exec "${wine}/bin/wine" "$exe_path"
	'';

	robotstudioWinetricks = pkgs.writeShellScriptBin "robotstudio-winetricks" ''
		set -euo pipefail

		export WINEARCH=win64
		export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/wine/abb-robotstudio"
		export WINEDLLOVERRIDES="mscoree,mshtml="

		mkdir -p "$WINEPREFIX"
		if [[ ! -f "$WINEPREFIX/system.reg" ]]; then
			"${wine}/bin/wineboot" -u
			"${wine}/bin/winecfg" -v win10 >/dev/null 2>&1 || true
		fi

		"${wine}/bin/wine" reg add "HKCU\\Control Panel\\Desktop" /v LogPixels /t REG_DWORD /d 144 /f >/dev/null 2>&1 || true
		"${wine}/bin/wine" reg add "HKCU\\Control Panel\\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >/dev/null 2>&1 || true

		"${wine}/bin/wine" msiexec /i ${wineMono}
		exec ${pkgs.winetricks}/bin/winetricks -q win10 corefonts msxml6 fontsmooth=rgb vcrun2022 dotnet48
	'';
in {
	environment.systemPackages = with pkgs; [
		wine
		winetricks
		robotstudio
		robotstudioWinetricks
	];
}
