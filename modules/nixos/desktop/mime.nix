{ config, lib, ... }:
let
  assoc = app: types: lib.genAttrs types (_: app);
in
lib.mkIf config.desktop.enable {
  xdg.mime.defaultApplications =
    assoc "thunar.desktop" [ "inode/directory" ]
    // assoc "firefox.desktop" [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "application/pdf"
    ]
    // assoc "nvim.desktop" [
      "text/plain"
      "text/markdown"
      "text/x-shellscript"
      "text/x-python"
      "text/x-csrc"
      "text/x-chdr"
      "text/x-c++src"
      "text/rust"
      "text/x-nix"
      "text/x-lua"
      "application/json"
      "application/toml"
      "application/x-yaml"
      "application/xml"
      "application/x-shellscript"
    ]
    // assoc "org.gnome.FileRoller.desktop" [
      "application/zip"
      "application/x-tar"
      "application/gzip"
      "application/x-compressed-tar"
      "application/x-bzip2-compressed-tar"
      "application/x-xz-compressed-tar"
      "application/x-zstd-compressed-tar"
      "application/zstd"
      "application/x-7z-compressed"
      "application/vnd.rar"
      "application/x-rar"
    ]
    // lib.optionalAttrs config.apps.media.enable (
      assoc "swayimg.desktop" [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/avif"
        "image/heic"
        "image/heif"
        "image/jxl"
        "image/bmp"
        "image/tiff"
        "image/svg+xml"
        "image/x-icon"
      ]
      // assoc "mpv.desktop" [
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/quicktime"
        "video/x-msvideo"
        "video/mpeg"
        "audio/mpeg"
        "audio/flac"
        "audio/ogg"
        "audio/opus"
        "audio/wav"
        "audio/x-wav"
        "audio/aac"
        "audio/mp4"
      ]
    );
}
