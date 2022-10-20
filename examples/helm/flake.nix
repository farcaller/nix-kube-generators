{
  inputs = {
    nix-kube-generators.url = "../../";
  };

  outputs = { self, nixpkgs, nix-kube-generators }:
    let
      nkg = import nix-kube-generators { inherit nixpkgs; };
    in
    with nkg.lib;
    {
      kubernetesObjects.argocd = fromHelm {
        name = "argocd";
        repo = "https://argoproj.github.io/argo-helm";
        chart = "argo-cd";
        version = "5.6.0";
        chartHash = "sha256-9uozvaMAZi12zuALsWw8z0F1UKgW3JgM7n6fUF8/kws=";
      };
      kubernetesResources = mkResources self.kubernetesObjects;
    };
}
