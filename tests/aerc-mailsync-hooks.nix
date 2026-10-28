# `mailsync-now` starts the scheduled mail sync job, so aerc must only run it
# from hooks on hosts that define that job. Elsewhere every send, move, flag
# change, and quit reports a failed hook.
{ lib, hosts }:
let
  homeFiles = host: host.config.home-manager.users.${host.config.my.username}.home.file;
in
lib.mapAttrs (
  _: host:
  let
    aercConf = (homeFiles host).".config/aerc/aerc.conf".text;
    hasSyncJob =
      (host.config.launchd.user.agents or { }) ? mailsync
      || (host.config.systemd.user.services or { }) ? mailsync;
  in
  assert lib.hasInfix "=mailsync-now" aercConf == hasSyncJob;
  true
) (lib.filterAttrs (_: host: homeFiles host ? ".config/aerc/aerc.conf") hosts)
