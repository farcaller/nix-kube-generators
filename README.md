# nix kube generators

A set of functions helping to generate k8s yaml. just pass pkgs along to the
lib function:

```nix
kubelib = nix-kube-generators.lib { inherit pkgs; };
```

## Functions

### FromYAML [yaml]

Parse a YAML string. If source YAML has several documents a list of them
is returned.

### toYAMLFile [object]

Serialize the object into a YAML file.

Note that generally builtins.toJSON _is_ a valid YAML. This function is
only to be used for extra readability.

### DownloadHelmChart [repo] [chart] [version] ([chartHash])

Download a helm chart. This can used indrectly with charts via
[nixhelm](https://github.com/farcaller/nixhelm). The correct chartHash
must be specified. To evaluate it, build the derivation without the hash first
(or with a wrong hash).

### BuildHelmChart [name] [chart] ([namespace] [values] [includeCRDs] [kubeVersion] [apiVersions])

Build a YAML containing the evaluated chart.

Chart should point to a directory with the chart source(or directly pass
`downloadHelmChart` result).

### fromHelm

Build a helm chart and return it as parsed YAML. Accepts the same arguments
as buildHelmChart.
