{ lib
, pkgs
, options
, config
, ...
}:


with lib; let
  cfg = config.age;

  isDarwin = lib.attrsets.hasAttrByPath ["environment" "darwinConfig"] options;

  substituteSecret = secretType:
    builtins.concatStringsSep "\n" (builtins.map (file: ''
      echo "substituting secret from '${secretType.path}' into '${file}'..."
      ${pkgs.gnused}/bin/sed -i "s#@${secretType.name}@#$(cat ${secretType.path})#" ${file}
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
        '';
      };
    };
  });
in 
{
  options = {
    age.secrets = mkOption {
      type = types.attrsOf secretType;
    };
  };

  config = mkIf (cfg.secrets != {}) (mkMerge [
    (optionalAttrs (!isDarwin) {
      system.activationScripts.agenixSubstitute = {
        text = substituteSecrets;
        deps = ["agenix" "etc"];
      };
    })
  ]);
}