(import ./default.nix { nixpkgs = <nixpkgs>; }).lib.fromHelm ({
  name = "argocd";
  repo = "https://argoproj.github.io/argo-helm";
  chart = "argo-cd";
  version = "5.6.0";
  chartHash = "sha256-9uozvaMAZi12zuALsWw8z0F1UKgW3JgM7n6fUF8/kws=";
})
