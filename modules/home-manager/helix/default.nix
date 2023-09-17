# helix module

{}: {


  enable = true;

  settings = {
    theme = "adwaita-dark";
    editor = {
      line-number = "relative";
      lsp.display-messages = true;
    };
    keys.normal = {
      space.space = "file_picker";
      space.f = ":fmt";
      space.w = ":w";
      space.q = ":q";
      space.t = ":run-shell-command foot";
      space.u = ":run-shell-command nix-shell --run foot";
      "C-j" = [ "move_visual_line_down" "move_visual_line_down" "move_visual_line_down" ];
      "C-k" = [ "move_visual_line_up" "move_visual_line_up" "move_visual_line_up" ];
      esc = [ "collapse_selection" "keep_primary_selection" ];
    };
  };
  languages = {
    language = [
      {
        name = "rust";
        auto-format = false;
      }
      {
        name = "nix";
        formatter = { command = "nixpkgs-fmt"; };
      }
      {
        name = "python";
      }
      {
        name = "go";
        # "autoSearchPaths" = true;
      }
    ];
  };

}
