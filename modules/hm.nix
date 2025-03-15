{ lib
, pkgs
, config
, ...
}:


with lib; let
  cfg = config.age;

  substituteSecret = secretType:
    builtins.concatStringsSep "\n" (builtins.map (file: ''
      echo "substituting secret from '${secretType.path}' into '${file}'..."
      ${pkgs.gnused}/bin/sed -i "s#@${secretType.name}@#$(cat "${secretType.path}")#" ${file}
    '')
    secretType.substitutions);

  substituteSecrets = builtins.concatStringsSep "\n" (
    ["echo '[agenix] substituting secrets...'"]
    ++ (map substituteSecret (builtins.attrValues cfg.secrets))
  );

  secretType = types.submodule ({ ... }: {
    options = {
      substitutions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          List of files to substitute the secret into.
          WARNING: It is recommended to set `force = true` for files managed through home-manager.
        '';
      };
    };
  });

  substituteScript = let
    app = pkgs.writeShellApplication {
      name = "agenix-home-manager-substitute-secrets";
      runtimeInputs = with pkgs; [coreutils];
      text = ''
        ${substituteSecrets}
        exit 0
      '';
    };
  in
    lib.getExe app;
in
{
  options = {
    age.secrets = mkOption {
      type = types.attrsOf secretType;
    };
  };

  config = mkIf (cfg.secrets != {}) {
    systemd.user.services.agenix-substitutes = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "agenix substitution";
        X-SwitchMethod = "restart";
        After = [ "agenix.service" ];
        Requires = [ "agenix.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = substituteScript;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}