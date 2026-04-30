{
  inputs,
  dotnix-constants,
}: {
  # Export configurations to home-manager's scope
  hmConfig = value:
    inputs.nixpkgs.lib.attrsets.setAttrByPath
    [
      "users"
      dotnix-constants.user.name
    ]
    value;

  hmModule = value:
    inputs.nixpkgs.lib.attrsets.setAttrByPath
    [
      "users"
      dotnix-constants.user.name
      "imports"
    ]
    [value];
}
