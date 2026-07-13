{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "molly.computer";
        email = "molly@molly.computer";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = false;
      core.editor = "hx";
    };
  };
}
