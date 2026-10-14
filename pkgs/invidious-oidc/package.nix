# Invidious with OpenID Connect support, pinned to the DanieleS fork.
# nixpkgs' invidious is the same upstream base (2.20260804.1) and pins the
# same shards, so only the source tree is swapped. The fork adds in-app OIDC
# login (oidc_issuer/oidc_client_id/...) and private_instance.
{
  invidious,
  fetchFromGitHub,
}:
invidious.overrideAttrs (_old: {
  # Upstream's spec suite needs the `mocks` submodule, which the fork does
  # not publish; the binary build does not.
  doCheck = false;
  src = fetchFromGitHub {
    owner = "DanieleS";
    repo = "invidious";
    rev = "31ce29b0078247c5d8bea6e691d588c01f6b1082";
    # The `mocks` submodule points at a non-public repo and is test-only.
    fetchSubmodules = false;
    hash = "sha256-uVgV+leA3IrX5ps+crCcoayLIg6vqCStYtotgvqLTXs=";
  };
})
