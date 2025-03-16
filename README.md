# Agenix Substitutes

A [NixOS](https://nixos.org/) and [Home-Manager](https://github.com/nix-community/home-manager) module to enable the substitution of [agenix](https://github.com/ryantm/agenix) secrets into files at runtime.

### Install

Both the NixOS and Home-Manager modules are available to install via flakes. The NixOS module is given by the flake output `nixosModules.default` and the Home-Manager module is given by the flake output `homeManagerModules.default`. Just import the relevant module(s) into your configuration.

**Note:** The corresponding agenix module must also be installed.

### Usage

For example, assume we have a secret setup through agenix like so:
```nix
{
    age.secrets.example = {
        file = ./example.age;
    };
}
```
Now suppose we wish to use this secret in a file `example.conf` that looks like:
```
[entry]
secret = *******
```
First, we include the path to the file in `age.secrets.example.substitutions`.
```nix
{
    age.secrets.example = {
        file = ./example.age;
        substitutions = [ "example.conf" ];
    };
}
```
Then update the file to reference this secret using the syntax `@<name>@`.
```
[entry]
secret = @example@
```
This placeholder will be substituted after agenix decrypts the secret.

**Note:** It is currently recommended to enable `home.file."example.conf".force` when using the Home-Manger module.