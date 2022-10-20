{ nixpkgs }:
with import nixpkgs { system = "x86_64-linux"; };
rec {
  fromHelm = { name, repo, chart, version, namespace ? null, values ? { }, chartHash }:
    let
      buildHelm = pkgs.stdenv.mkDerivation {
        name = "loadHelm-${repo}-${chart}-${version}";
        nativeBuildInputs = [ pkgs.cacert ];

        phases = [ "installPhase" ];
        installPhase = ''
          export HELM_CACHE_HOME=/tmp/.nix-helm-build-cache

          ${pkgs.kubernetes-helm}/bin/helm template \
          --include-crds \
          ${if (!builtins.isNull namespace) then "--namespace \"${namespace}\"" else ""} \
          --repo "${repo}" \
          --version "${version}" \
          --values ${writeText "values.yaml" (builtins.toJSON values)} \
          "${name}" \
          "${chart}" \
          > $out
        '';

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = chartHash;
      };
    in
    fromYAML buildHelm;

  fromYAML = yamlFile:
    let
      mkJSON = (pkgs.stdenv.mkDerivation {
        inherit yamlFile;
        name = "fromYAML";
        phases = [ "buildPhase" ];
        passAsFile = [ "yamlFile" ];
        buildPhase = "${pkgs.yq-go}/bin/yq -o j -M -I0 < ${yamlFile} > $out";
      });
      readJSON = builtins.readFile mkJSON;
      goodLine = line: builtins.isString line && builtins.stringLength line > 0;
      jsonLines = builtins.filter goodLine (builtins.split "\n" readJSON);
      parsed = map builtins.fromJSON jsonLines;
      nonNull = builtins.filter (v: v != null) parsed;
    in
    nonNull;

  toYAML = object:
    let
      yamlData = writeText "yamldata.yaml" (builtins.toJSON object);
    in
    (pkgs.stdenv.mkDerivation {
      name = "toYAML";
      phases = [ "buildPhase" ];
      buildPhase = "cat ${yamlData} | ${pkgs.yq-go}/bin/yq -P > $out";
    });

  mkResources = objects:
    let
      keys = builtins.attrNames objects;
      toYaml = name: { inherit name; value = toYAML objects.${name}; };
    in
    builtins.listToAttrs (map toYaml keys);
}
