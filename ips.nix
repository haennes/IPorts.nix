{ lib, ... }@inputs:
let
  inherit (lib)
    mkOption mapAttrsRecursive mapAttrsRecursiveCond concatStringsSep flatten
    collect isList splitString head last replaceStrings setAttrByPath
    mkEnableOption;
  inherit (lib.types) submodule attrsOf anything;
  inherit (import ./lib.nix inputs) recursiveMergeNoOverride mapAttrsFunc;

  mapAttrsToPathValueList = set:
    (mapAttrsRecursive (path: value:
      let
        spl = splitString ":" value;
        service = splitString "." (replaceStrings [ "%" ] [ "." ] (head spl));
        iface = last spl;
        ip = concatStringsSep "." path;
      in [{
        inherit ip service;
        setForIf = if iface == "" then false else true;
      }]) set);

  flatten_attrs_list = set:
    flatten (collect isList (collect isList (mapAttrsToPathValueList set)));
  flatten_attrs_rec = host_ports:
    recursiveMergeNoOverride (map (eth_attrs:
      setAttrByPath (eth_attrs.service) ({ inherit (eth_attrs) ip setForIf; }))
      (flatten_attrs_list host_ports));

  flatten_attrs_non_rec = host_ports:
    recursiveMergeNoOverride (map (eth_attrs: {
      "${concatStringsSep "." eth_attrs.service}" = {
        inherit (eth_attrs) ip setForIf;
      };
    }) (flatten_attrs_list host_ports));

  map_to_ips = set:
    mapAttrsRecursiveCond (as:
      !(as
        ? ip)) # this assumes that you dont use port as a path inside your key!
    (_: x: x.ip) set;

in {
  options.ips = mkOption {
    type = (submodule {
      options = {
        ips = mkOption {
          type = attrsOf (anything);
          description = "";
          apply = old: rec {
            raw = old;

            #flattened = mapAttrsFunc flatten_attrs_list old;
            flattened = mapAttrsFunc flatten_attrs_non_rec old;
            full = mapAttrsFunc flatten_attrs_rec old;
            ips = mapAttrsFunc map_to_ips full;

          };
        };
        setForIf.enable = mkEnableOption
          "Enables setting ips for interfaces, if specified for the ip";
      };
    });
  };
}
