{ lib, ... }:
let inherit (lib) mapAttrs foldr recursiveUpdate;
in {
  mapAttrsFunc = f: set: (mapAttrs (name: value: f value) set);
  recursiveMergeNoOverride = listOfAttrsets:
    foldr (attrset: acc: recursiveUpdate attrset acc)
    { } # TODO fix to disallow same path
    listOfAttrsets;

}
