{ config, lib, ... }@inputs:
let
  inherit (import ./lib.nix inputs) mapAttrsFunc recursiveMergeNoOverride;
  inherit (lib.types) anything submodule attrsOf;
  inherit (lib)
    mkOption mkEnableOption mapAttrs concatStringsSep mapAttrsRecursive collect
    isList isInt last head tail replaceStrings stringLength genList
    stringToCharacters toList imap0 flatten setAttrByPath splitString length
    mapAttrsRecursiveCond groupBy removeAttrs filter attrValues elem;

  hostname = config.networking.hostName;
  cfg = config.ports;
  cfgp = config.ports.ports;
  portstring_to_attrs = str:
    let
      colon_split = splitString ":" str;
      pre_colon_split = splitString "%" (head colon_split);
      pre_forward = {
        type = if (length colon_split > 1) then
          stringToCharacters (last colon_split)
        else
          null;
        interface =
          if (length pre_colon_split > 1) then last pre_colon_split else null;
      };
    in {
      path = (splitString "." (head pre_colon_split))
        ++ (if (length pre_colon_split > 1) then
          [ (last pre_colon_split) ]
        else
          [ ]);
      forward = if pre_forward.type == null then null else pre_forward;
    };

  intToStringFixedLength = num: offset: length:
    let
      str = toString (num + offset);
      len = stringLength str;
      len_diff = length - len;
    in (concatStringsSep ""
      ((genList (x: "0") len_diff) ++ (stringToCharacters str)));

  #evaluates to sth like "8" = { "384" = [["8384" "host"]];};
  mapAttrsToPathValueList = set:
    (mapAttrsRecursive (path: value:

      let
        path_concat = concatStringsSep "" path;
        count_x = lib.count (c: c == "x") (stringToCharacters path_concat);
        path_clean = replaceStrings [ "x" ] [ "" ] path_concat;
        list_value = toList value;
        new_value =
          if isInt (head list_value) then tail list_value else list_value;
      in imap0 (idx: service: {
        port = (concatStringsSep "" ([ path_clean ] ++ (if isList value then
          let offset = if isInt (head value) then head value else 0;
          in [ (intToStringFixedLength idx offset count_x) ]
        else
          [ ])));
        inherit service;
      }) new_value) set);

  #evaluates from "8" = { "384" = [["8384" "host"]];}; -> [{ service = "host" port_spec]] #NOTE WE DO Some kind of flattening once
  flatten_attrs_list = set:
    flatten (collect isList (collect isList (mapAttrsToPathValueList set)));
  flatten_attrs_rec = host_ports:
    recursiveMergeNoOverride (map (port_service:
      let port_spec = portstring_to_attrs port_service.service;
      in setAttrByPath (port_spec.path) ({
        inherit (port_service) port;
        inherit (port_spec) forward;
      })) (flatten_attrs_list host_ports));

  flatten_attrs_non_rec = host_ports:
    recursiveMergeNoOverride (map (port_service:
      let
        port_spec = portstring_to_attrs port_service.service;
        name = concatStringsSep "." (port_spec.path);
      in {
        "${name}" = {
          inherit (port_service) port;
          inherit (port_spec) forward;
        };
      }) (flatten_attrs_list host_ports));

  map_to_ports = set:
    mapAttrsRecursiveCond (as:
      !(as
        ? port)) # this assumes that you dont use port as a path inside your key!
    (_: x: x.port) set;
in {
  options.ports = mkOption {
    default = {
      addToFirewall.enable = false;
      ports = { };
    };
    type = (submodule {
      options = {
        addToFirewall.enable = mkEnableOption "Enable port management";
        ports = mkOption {
          type = attrsOf (anything);
          default = { };
          description = "";

          apply = old: rec {
            raw = old;

            # an attrset with the most inner value being the port number
            ports = mapAttrsFunc map_to_ports full;
            curr_ports = ports."${hostname}";

            # inside .${hostname} is:
            #  ${service_name flattened} = {forward = { interface = ...; type = [ ... ...];}; port="${port}";};
            flattened = mapAttrsFunc flatten_attrs_non_rec old;
            curr_flattened = flattened."${hostname}";

            # like flattened, but the service name is not concatonated to a string
            full = mapAttrsFunc flatten_attrs_rec old;
            curr_full = full."${hostname}";

            # inside .${hostname} list of {port = ... , service = ...}
            list = mapAttrsFunc flatten_attrs_list old;
            curr_list = list."${hostname}";

          };
        };
      };
    });
  };

  config = lib.mkIf (cfg.addToFirewall.enable) (let
    forwards = filter (x: x.forward != null) (attrValues cfgp.curr_flattened);
    by_interface = groupBy (a:
      let intf = a.forward.interface;
      in if intf == null then "null" else intf) forwards;
    by_interface_non_global = removeAttrs by_interface [ "null" ];
    global = by_interface."null";

    map_to_port = list: map (x: lib.toInt (x.port)) list;

    filter_packet_type = type: list:
      filter (x: (elem type x.forward.type) || (elem null x.forward.type)) list;

    tcp = filter_packet_type "t";
    tcpp = list: map_to_port (tcp list);

    udp = filter_packet_type "u";
    udpp = list: map_to_port (udp list);

  in {
    networking.firewall = {
      allowedTCPPorts = tcpp global;
      allowedUDPPorts = udpp global;
      interfaces = mapAttrs (_name: value: {
        allowedTCPPorts = tcpp value;
        allowedUDPPorts = udpp value;
      }) by_interface_non_global;
    };
  });
}
