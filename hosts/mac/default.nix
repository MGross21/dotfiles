{ ... }:
{
  networking.hostName = "mac";

  theming.name = "osaka-jade";

  dev = {
    jvm.enable = false;
    android.enable = false;
    apple.enable = true;
  };
}
