{lib, ...}:
let inherit (lib) mapAttrs fold recursiveUpdate;
in
{
  mapAttrsFunc = f: set: (mapAttrs(name: value: f value) set);
  recursiveMergeNoOverride = listOfAttrsets:
          fold (attrset: acc: recursiveUpdate attrset acc) { } #TODO fix to disallow same path
          listOfAttrsets;


}
