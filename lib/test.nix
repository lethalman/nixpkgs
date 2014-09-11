with import (./customisation.nix);

rec {
  pkgs1 = overridableAttrs (self: with self; {
      x = 1;
      y = 1;
      r = x+y;
      subset1 = with subset1; {
        xx = 4;
        zz = xx+y;

        subset2 = with subset2; {
          xxx = 2;
          zzz = zz+xx;
        };
      };
  });

  pkgs2 = pkgs1.overrideAttrs (super: self: with self; {
      x = 2;
      z = r+x+y;
      subset1 = super.subset1 // (with subset1; {
        xx = 1;
        ww = zz+x;

        subset2 = super.subset1.subset2 // (with subset2; {
            xxx = ww;
        });
      });
  });

  pkgs3 = pkgs2.overrideAttrs (super: self: with self; {
      w = z+x;
      y = 3;
      subset1 = super.subset1 // {
        xx = 2;
      };
  });
  
}
