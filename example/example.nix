{ ... }: {
  networking.hostName = "host1";
  ports = {
    addToFirewall.enable = true;
    ports = {
      "host1" = {
        "1xxx" = {
          #deeper nested attributes SHOULD all be exactly count("x")
          #this ensures collisions when defining in a consistent way at this point
          #otherwise they will be caught later
          "234" = "a.b:u";
          "235" = "a.c%wg0:t";
        };
        "2xxxx" = {
          "3456" = "c.b%wg0"; # assumes nothing
          "3457" = "c.c";
          "3459" = "c.d:t";
          #setting c should be illegal
        };
        "885xx" = [
          "services.a.one" # 88500
          "services.a.two" # 88501
        ];
        "886xx" = [
          8 # start at an offset of 8
          "services.b.one" # 88608
          "services.b.two" # 88609
        ];
      };
    };
  };
  ips = {
    ips."lan1" = {
      "192.168.178" = {
        "1" =
          "a%wg0:eth"; # add as ethernet interface alternatively could also use
        "2" = "b%wg0";
      };
      "192.168.178.3" = "a%eth0:"; # same as without. do not add to anything
    };
  };

  macs = { host1 = { "02:01" = { "00:00:00:01" = "test%br0"; }; }; };
}

#maps to: contents in example_eval.nix

