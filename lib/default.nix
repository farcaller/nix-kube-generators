{ pkgs }:
rec {
  /* Parse a yaml string. Returns a list of yaml documents.
  */
  fromYAML = yaml: pkgs.lib.pipe yaml [
    (yaml: (pkgs.stdenv.mkDerivation {
      inherit yaml;
      passAsFile = "yaml";
      name = "fromYAML";
      phases = [ "buildPhase" ];
      buildPhase = "${pkgs.busybox}/bin/cat $yamlPath | ${pkgs.yq}/bin/yq -Ms . > $out";
    }))
    builtins.readFile
    builtins.fromJSON
  ];

  /* Serialize the object into a yaml file.
  
    Note that generally builtins.toJSON *is* a valid yaml. This function is
    only to be used for extra readability.
  */
  toYAMLFile = obj: pkgs.stdenv.mkDerivation {
    yamlText = builtins.toJSON obj;
    passAsFile = "yamlText";
    name = "toYAMLFile";
    phases = [ "buildPhase" ];
    buildPhase = "${pkgs.yq-go}/bin/yq -P -M $yamlTextPath > $out";
  };

  /* Serialize the objects into a file containing a yaml documents stream. */
  toYAMLStreamFile = objs: pkgs.stdenv.mkDerivation {
    yamlText = pkgs.lib.strings.concatStringsSep "\n---\n" (map builtins.toJSON objs);
    passAsFile = "yamlText";
    name = "toYAMLFile";
    phases = [ "buildPhase" ];
    buildPhase = "${pkgs.yq-go}/bin/yq -P -M $yamlTextPath > $out";
  };

  /* Download a helm chart.

    The correct chartHash must be specified. To evaluate it, build the
    derivation without the hash first (or with a wrong hash).
  */
  downloadHelmChart = { repo, chart, version, chartHash ? pkgs.lib.fakeHash }: pkgs.stdenv.mkDerivation {
    name = "helm-chart-${repo}-${chart}-${version}";
    nativeBuildInputs = [ pkgs.cacert ];

    phases = [ "installPhase" ];
    installPhase = ''
      export HELM_CACHE_HOME="$TMP/.nix-helm-build-cache"

      OUT_DIR="$TMP/temp-chart-output"

      mkdir -p "$OUT_DIR"

      ${pkgs.kubernetes-helm}/bin/helm pull \
      --repo "${repo}" \
      --version "${version}" \
      "${chart}" \
      -d $OUT_DIR \
      --untar

      mv $OUT_DIR/${chart} "$out"
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = chartHash;
  };

  /* Build a yaml containing the evalauted chart.

    Chart should point to a directory with the chart source (provided by
    downloadHelmChart).
  */
  buildHelmChart =
    { name
    , chart
    , namespace ? null
    , values ? { }
    , includeCRDs ? true
    , kubeVersion ? "v${pkgs.kubernetes.version}"
    , apiVersions ? [ ]
    }:
    let
      hasNamespace = !builtins.isNull namespace;
      helmNamespaceFlag = if hasNamespace then "--namespace ${namespace}" else "";
      namespaceName = if hasNamespace then "-${namespace}" else "";
    in
    pkgs.stdenv.mkDerivation {
      name = "helm-${chart}${namespaceName}-${name}";

      passAsFile = [ "helmValues" ];
      helmValues = builtins.toJSON values;
      helmCRDs = if includeCRDs then "--include-crds" else "";
      inherit kubeVersion;

      phases = [ "installPhase" ];
      installPhase = ''
        export HELM_CACHE_HOME="$TMP/.nix-helm-build-cache"

        ${pkgs.kubernetes-helm}/bin/helm template \
        $helmCRDs \
        ${helmNamespaceFlag} \
        --kube-version "$kubeVersion" \
        --values "$helmValuesPath" \
        "${name}" \
        "${chart}" \
        ${builtins.concatStringsSep " " (map (v: "-a ${v}") apiVersions)} \
        >> $out
      '';
    };

  /* Build a helm chart and return it as parsed yaml. Accepts the same arguments
    as buildHelmChart.
  */
  fromHelm = args: pkgs.lib.pipe args [ buildHelmChart builtins.readFile fromYAML ];

  /* Creates a kubernetes List object. */
  mkList = objs: {
    apiVersion = "v1";
    kind = "List";
    items = objs;
  };
}
