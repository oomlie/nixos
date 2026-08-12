{lib, ...}: {
  # oh-my-pi (omp) coding agent — installed globally via npm; bun runtime
  # lives in ~/.bun (official installer, nixpkgs bun is too old: needs >= 1.3.14)
  # Provider config (~/.omp/agent/models.yml) points at halo.daze.lol gpt-oss.
  home.activation.installOhMyPi = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v npm >/dev/null 2>&1 && [ ! -x "$HOME/.npm-global/bin/omp" ]; then
      echo "Installing @oh-my-pi/pi-coding-agent..."
      npm install -g @oh-my-pi/pi-coding-agent || echo "warning: oh-my-pi install failed, run manually later"
    fi
  '';
}
