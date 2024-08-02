{
  networking.firewall = {
    allowedUDPPorts = [ 1234 ];
    allowedTCPPorts = [ 23459 ];
    interface.wg0 = {
      allowedUDPPorts = [ 23456 1235];
      allowedTCPPorts = [ 23456];
    };
  };

  ports.ports = {
    raw = {
      "host1" = {
        "1"  = {
          "234" = "a.b:u";
          "235" = "a.c%wg0:t"; #:t <=> :tcp
        };
        "2" = {
          #"3456" = "c.b%wg0:tu"; #assumes nothing
          "3456" = "c.b%wg0"; #assumes nothing
          "3457" = "c.c";
          "3459" = "c.d:t";
          #setting c should be illegal
        };
      };
    };
    flat = {
    "host1" = {
        "1234" = "a.b:u";
        "1235" = "a.c%wg0:t";
        "23456" = "c.b%wg0";
        "23457" = "c.c";
        "23459" = "c.d:t";
      };
    };

    flatattr = {
      "host1" = {
        "1234" = {name = "a.b"; forwarding = {interface = "global"; protocol ="udp";};};
        "1235" = {name = "a.c"; forwarding = {interface = "wg0"; protocol = "tcp";};};
        "23456"= {name = "c.b"; forwarding = {interface = "wg0"; protocol = "any";};};
        "23457"= {name = "c.c"; forwarding = {interface = "global"; protocol = null;};};
        "23459"= {name = "c.d"; forwarding = {interface = "global"; protocol = "tcp";};};
      };
    };

    rev = {
      "host1" = {
        "a.b" = "1234";
        "a.c" = "1235";
        "c.b" = "23456";
        "c.c" = "23457";
        "c.d" = "23459";
      };
    };
  };

  ips.ips = {
   raw = {
      "lan1" = {
        "192.168.17" = {
          "8.1" = "a%wg0";
          "8.2" = "b%wg0";
        };
        "192.168.178.2" = "a%eth0";
      };
    };
   flat = {
     "lan1" = {
        "192.168.178.1" = "a%wg0";
        "192.168.178.2" = "b%wg0";
        "192.168.178.3" = "a%eth0";
     };
   };
   flatattr = {
     "lan1" = {
        "192.168.178.1" = "a.wg0";
        "192.168.178.2" = "b.wg0";
        "192.168.178.3" = "a.eth0";
     };
   };

   rev = {
     "lan1" = {
        "a.wg0"  = "192.168.178.1";
        "b.wg0"  = "192.168.178.2";
        "a.eth0" = "192.168.178.3";
     };
   };
  };

}
