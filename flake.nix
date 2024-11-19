{
  description = "faster shell navigation of projects";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
      });
    in
    {
      packages = forEachSupportedSystem ({ pkgs, ... }: {
        default = import ./default.nix { inherit pkgs; };
      });

      darwinModules.default = { lib, config, pkgs, ... }:
        let
          h = self.packages.${pkgs.stdenv.system}.default;
        in
        {
          options = {
            programs.h = {
              codeRoot = lib.mkOption {
                type = lib.types.str;
                default = "~/src";
                description = lib.mdDoc ''
                  Root location for checking out your code.
                '';
              };

              jj = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.mdDoc ''
                  Automatically setup jj colocation with Git repositories.
                '';
              };
            };
          };
          config = {
            environment.systemPackages = [ h ];

            environment.extraInit = ''
              eval "$(${h}/bin/h --setup ${lib.escapeShellArg config.programs.h.codeRoot} ${if lib.escapeShellArg config.programs.h.jj then "--jj" else "--no-jj"})"
            '';
          };
        };

      homeModules.default = { lib, config, pkgs, ... }:
        let
          h = self.packages.${pkgs.stdenv.system}.default;
        in
        {
          options = {
            programs.h = {
              codeRoot = lib.mkOption {
                type = lib.types.str;
                default = "~/src";
                description = lib.mdDoc ''
                  Root location for checking out your code.
                '';
              };

              jj = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.mdDoc ''
                  Automatically setup jj colocation with Git repositories.
                '';
              };
            };
          };
          config = let
            hook = ''
              eval "$(${h}/bin/h --setup ${lib.escapeShellArg config.programs.h.codeRoot} ${if lib.escapeShellArg config.programs.h.jj then "--jj" else "--no-jj"})"
            '';
          in {
            home.packages = [ h ];

            programs.bash.initExtra = hook;
            programs.zsh.initExtra = hook;
            programs.fish.functions.h = {
              body = ''
                set _h_dir $(${h}/bin/h --resolve $(path resolve ${config.programs.h.codeRoot}) $argv)
                set _h_ret $status
                if test "$_h_dir" != "$PWD"
                  cd "$_h_dir"
                end
                return $_h_ret
              '';
              wraps = "h";
            };
          };
        };
    };
}
