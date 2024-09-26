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
        interface = splitString "." (replaceStrings [ "%" ] [ "." ] (head spl));
        mac = concatStringsSep ":" path;
      in [{ inherit mac interface; }]) set);

  flatten_attrs_list = set:
    flatten (collect isList (collect isList (mapAttrsToPathValueList set)));
  flatten_attrs_rec = host_ports:
    recursiveMergeNoOverride (map (eth_attrs:
      setAttrByPath (eth_attrs.interface) ({ inherit (eth_attrs) mac; }))
      (flatten_attrs_list host_ports));

  flatten_attrs_non_rec = host_ports:
    recursiveMergeNoOverride (map (eth_attrs: {
      "${concatStringsSep "." eth_attrs.interface}" = {
        inherit (eth_attrs) mac;
      };
    }) (flatten_attrs_list host_ports));

  map_to_ips = set:
    mapAttrsRecursiveCond (as:
      !(as
        ? mac)) # this assumes that you dont use port as a path inside your key!
    (_: x: x.mac) set;

in {
  options.macs = mkOption {
    type = attrsOf (anything);
    default = { };
    description = "";
    apply = old: rec {
      raw = old;

      #flattened = mapAttrsFunc flatten_attrs_list old;
      flattened = mapAttrsFunc flatten_attrs_non_rec old;
      full = mapAttrsFunc flatten_attrs_rec old;
      macs = mapAttrsFunc map_to_ips full;

    };
  };
}
