{pkgs, ...}: {
  programs.mpv = {
    enable = true;

    scripts = with pkgs.mpvScripts; [
      # Skips sponsored/self-promo segments in YouTube videos
      sponsorblock

      # Auto-queues sibling files in a directory; same_type (below) keeps
      # images and videos from mixing into the same playlist
      builtins.autoload

      # mpv-image-viewer: keeps the window size stable between files, adds
      # a filename/position status line, and gives zoom/pan commands
      mpv-image-viewer.freeze-window
      mpv-image-viewer.status-line
      mpv-image-viewer.image-positioning
    ];

    scriptOpts.autoload.same_type = true;

    config = {
      screenshot-directory = "~/Pictures/Screenshots";
    };

    # Image-viewer mode: these only take effect while an image is open — mpv
    # applies profiles named "extension.<ext>" automatically based on the
    # played file's extension, and reverts them again once a non-matching
    # file loads, so regular video playback is unaffected.
    profiles = let
      imageProfile = {
        mute = true;
        osc = false;
        sub-auto = "no";
        audio-file-auto = "no";
        image-display-duration = "inf";
        loop-file = "inf";
        video-aspect-override = "no";
        background = "color";
        background-color = "0.2";
        scale = "spline36";
        cscale = "spline36";
        dscale = "mitchell";
        correct-downscaling = true;
        sigmoid-upscaling = true;
      };
    in {
      "extension.jpg" = imageProfile;
      "extension.jpeg" = {profile = "extension.jpg";};
      "extension.png" = imageProfile;
      "extension.gif" = imageProfile;
      "extension.bmp" = imageProfile;
      "extension.webp" = imageProfile;
      "extension.avif" = imageProfile;
      "extension.tiff" = imageProfile;
    };

    bindings = {
      # Pan around a zoomed-in image (image-positioning.lua)
      "ctrl+Left" = "script-message pan-image x +0.05 yes yes";
      "ctrl+Right" = "script-message pan-image x -0.05 yes yes";
      "ctrl+Up" = "script-message pan-image y +0.05 yes yes";
      "ctrl+Down" = "script-message pan-image y -0.05 yes yes";
      "ctrl+0" = "no-osd set video-pan-x 0; no-osd set video-pan-y 0; no-osd set video-zoom 0";
    };
  };
}
