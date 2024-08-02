{...}:{
networking.hostName = "host1";
ports = {
  addToFirewall.enable = true;
  ports = {
    "host1" =
    {
      "1xxx"  = {
        #deeper nested attributes SHOULD all be exactly count("x")
        #this ensures collisions when defining in a consistent way at this point
        #otherwise they will be caught later
        "234" = "a.b:u";
        "235" = "a.c%wg0:t";
      };
      "2xxxx" = {
        "3456" = "c.b%wg0"; #assumes nothing
        "3457" = "c.c";
        "3459" = "c.d:t";
        #setting c should be illegal
      };
      "885xx" = [
        "services.a.one" # 88501
        "services.a.two" # 88502
      ];
    };
  };
};
ips = {
      "lan1" = {
        "192.168.17" = {
          "8.1" = "a%wg0:eth"; #add as ethernet interface alternatively could also use
          "8.2" = "b%wg0";
        };
        "192.168.178.3" = "a%eth0:"; #same as without. do not add to anything
      };
  };
}

#maps to: contents in example_eval.nix


