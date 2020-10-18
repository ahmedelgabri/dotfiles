{ pkgs, config, ... }:

{
  home-manager = {
    users.${config.settings.username} = { pkgs, ... }: {
      home = {
        packages = with pkgs; [ lbdb neomutt msmtp isync ];
        file = {
          ".config/neomutt/scripts/mail-sync" = {
            executable = true;
            text = ''
              #!/usr/bin/env sh
              # ${config.settings.nix_managed}

              # This will call notmuch `pre-new` hook that will fetch new mail & addresses too
              # Check `.mail/.notmuch/hooks/`
              ${pkgs.notmuch}/bin/notmuch --config=/Users/${config.settings.username}/.config/notmuch/config new'';
          };

          ".mail/.notmuch/hooks/pre-new" = {
            executable = true;
            text = ''
              #!/usr/bin/env sh
              # ${config.settings.nix_managed}

              ${pkgs.coreutils}/bin/timeout 2m ${pkgs.isync}/bin/mbsync -q -a

              find  /Users/${config.settings.username}/.mail/*/INBOX -type f -mtime -30d -print -exec sh -c 'cat {} | ${pkgs.lbdb}/bin/lbdb-fetchaddr' \; 2>/dev/null'';
          };
        };
      };
    };
  };

  environment.userLaunchAgents."com.ahmedelgabri.isync.plist".text = ''
    <!-- ${config.settings.nix_managed} -->
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.ahmedelgabri.isync</string>
        <key>ProgramArguments</key>
        <array>
          <string>/bin/sh</string>
          <string>-c</string>
          <string>exec /Users/${config.settings.username}/.config/neomutt/scripts/mail-sync</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StartInterval</key>
        <integer>120</integer>
        <key>StandardOutPath</key>
        <string>/tmp/ahmed.isync.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/ahmed.isync.err.log</string>
      </dict>
    </plist>
      '';
}
