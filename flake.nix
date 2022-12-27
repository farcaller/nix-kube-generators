{
  description = "Nix Generators for Kubernetes";

  outputs = { self }: {
    lib = { pkgs }: import ./lib { inherit pkgs; };
  };
}
