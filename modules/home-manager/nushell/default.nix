{ pkgs,... }:

{
  # home.username = "your_username";  # Replace with your username

  # ...


  enable = true;
  package = pkgs.nushell;
  # configFile.source = ./config.nu;
  # envFile.source = ./env.nu;



}
