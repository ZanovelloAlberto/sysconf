with import <nixpkgs> { };
# {}:
let
  # Use the let-in clause to assign the derivation to a variable
  myScript = pkgs.writeShellScriptBin "timer" ''
    (sleep $((60 * $1)); swaynag -m \$\{*:2}') &
  '';
  session = pkgs.writeShellScriptBin "session" ''
        timer 0 'session started'
        timer 20 '15*3 push up straight with handerr' 
        timer 40 "10*3 pull up reverse" 
        timer 60 '10*3 pull up straight" 
        timer 80 "10*3 right 10*3 left lats" 
    	timer 0 "session ended"
  '';
in
stdenv.mkDerivation rec {
  name = "test-environment";
  buidPhase = "mkdir -p $out";
  shellHook = ''
  
  '';

  # Add the derivation to the PATH
  buildInputs = with pkgs;
    [ myScript bash sway session ];
}
