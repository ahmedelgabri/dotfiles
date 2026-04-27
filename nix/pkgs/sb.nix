# sb — Linux VM sandbox for AI agents, backed by tart.
#
# Requires tart (not in nixpkgs):
#   brew install --cask tart
#
# Inspired by Greg Hurrell's sb.erb:
#   https://github.com/wincent/wincent/blob/main/aspects/dotfiles/templates/.zsh/bin/sb.erb
{
  formats,
  writeShellApplication,
  writeText,
  openssh,
  sshpass,
  jq,
  coreutils,
}: let
  gitIni = formats.gitIni {};
  toml = formats.toml {};

  gitConfigInVm = gitIni.generate "git-config.in-vm" {
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
    rebase = {
      autosquash = true;
      autoStash = true;
      updateRefs = true;
    };
    fetch.prune = true;
    rerere = {
      enabled = true;
      autoupdate = true;
    };
    diff = {
      algorithm = "histogram";
      renames = "copies";
    };
    merge.conflictstyle = "zdiff3";
    protocol.version = 2;
  };

  jjConfigInVm = toml.generate "jj-config.in-vm.toml" {
    git.push-bookmark-prefix = "sandbox/";
    ui = {
      default-command = "log";
      conflict-marker-style = "git";
      show-cryptographic-signatures = false;
    };
    template-aliases = {
      "format_short_change_id(id)" = "id.shortest()";
    };
    revset-aliases = {
      "empty_description()" = ''description(exact:"")'';
      "wip()" = ''description(glob:"wip:*") ~ ::immutable_heads()'';
      "private()" = ''(description(glob:"private:*") | wip())'';
    };
    revsets.log = ''present(@) | ancestors(immutable_heads().., 5) | present(trunk())'';
    aliases = {
      fetch = ["git" "fetch" "--all-remotes"];
      d = ["diff"];
      push = ["git" "push"];
    };
  };

  # Runs inside the build VM as root during `sb build-image`. aarch64 is
  # hard-coded because the cirruslabs Ubuntu image is aarch64 on Apple
  # Silicon. Bump JJ_VERSION manually.
  provisionScript =
    writeText "sb-provision.sh"
    /*
    bash
    */
    ''
      #!/usr/bin/env bash
      set -Eeuo pipefail
      export DEBIAN_FRONTEND=noninteractive
      # Silence locale noise during the bootstrap window (before `locales`
      # is installed). Dropped once the real locales are generated below.
      export LC_ALL=C.UTF-8

      JJ_VERSION="0.40.0"

      apt-get update -qq

      # Install and generate locales that match the host. SSH's SendEnv
      # forwards LC_TIME=en_GB.UTF-8 so that one must be available too.
      apt-get install -y -qq locales
      locale-gen en_US.UTF-8 en_GB.UTF-8
      update-locale LANG=en_US.UTF-8
      unset LC_ALL
      export LANG=en_US.UTF-8

      apt-get upgrade -y -qq
      apt-get install -y -qq \
        zsh git openssh-server curl wget ca-certificates gnupg \
        build-essential ripgrep fd-find jq unzip

      curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
      apt-get install -y -qq nodejs

      # Tarball is flat with a "./" prefix; extract only the binary.
      curl -fsSL \
        "https://github.com/jj-vcs/jj/releases/download/v''${JJ_VERSION}/jj-v''${JJ_VERSION}-aarch64-unknown-linux-musl.tar.gz" \
        | tar -xzO ./jj > /usr/local/bin/jj
      chmod +x /usr/local/bin/jj

      # Claude Code via the official installer, as the admin user.
      # -i runs a clean login shell so HOME resets to /home/admin.
      sudo -iu admin bash -c 'curl -fsSL https://claude.ai/install.sh | bash'

      # pi is npm-only.
      npm install -g @mariozechner/pi-coding-agent

      chsh -s /usr/bin/zsh admin
      systemctl enable ssh

      # Ensure ~/.local/bin (where claude.ai/install.sh lands) is on PATH
      # for both interactive and login shells.
      for f in /home/admin/.zshrc /home/admin/.zprofile /home/admin/.profile; do
        touch "$f"
        if ! grep -q '\.local/bin' "$f"; then
          echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$f"
        fi
        chown admin:admin "$f"
      done

      apt-get autoremove -y
      apt-get clean
    '';
in
  writeShellApplication {
    name = "sb";
    runtimeInputs = [openssh sshpass jq coreutils];

    # Disable a few shellcheck rules that fight bash patterns we rely on:
    #   SC2086 — intentional word splitting for option arrays.
    #   SC2016 — single-quoted strings that contain $ are deliberate.
    #   SC2154 — vars sourced from .sandboxrc are not statically visible.
    excludeShellChecks = ["SC2086" "SC2016" "SC2154"];

    text = ''
      export SB_GIT_CONFIG="${gitConfigInVm}"
      export SB_JJ_CONFIG="${jjConfigInVm}"
      export SB_PROVISION_SCRIPT="${provisionScript}"

      # ── Logging ────────────────────────────────────────────────────────────
      # All helpers write to stderr so stdout is reserved for subcommand
      # output (IPs, etc. captured in $()).
      info() { printf '\033[36m[sb]\033[0m %s\n' "$*" >&2; }
      ok()   { printf '\033[32m[sb]\033[0m %s\n' "$*" >&2; }
      err()  { printf '\033[31m[sb]\033[0m %s\n' "$*" >&2; exit 1; }

      require_tart() {
        if ! command -v tart >/dev/null 2>&1; then
          err "tart not found on PATH. Install with: brew install --cask tart"
        fi
      }

      # ── Constants ──────────────────────────────────────────────────────────
      BASE_IMAGE="agent-sandbox-base"
      BASE_IMAGE_SOURCE="ghcr.io/cirruslabs/ubuntu:latest"
      VM_USER="admin"
      VM_PASS="admin"

      # ── Overridable defaults ──────────────────────────────────────────────
      SB_VM_CPU=4
      SB_VM_MEMORY=8192
      SB_VM_DISK=50
      SB_BRANCHES=(main)
      SB_WORKTREES=()
      SB_PORTS=()
      SB_SOCKETS=()
      SB_REPO_SUBDIR="code"
      SB_VM_IMAGE=""
      SB_SSH_EXEC=""

      # Force password auth explicitly. The user's ~/.ssh/config may set
      # `PasswordAuthentication no` globally for `Host *`; without these
      # overrides sshpass has nothing to feed.
      SSH_OPTS=(
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o LogLevel=ERROR
        -o ConnectTimeout=5
        -o ControlPath=none
        -o PasswordAuthentication=yes
        -o PubkeyAuthentication=no
        -o PreferredAuthentications=password
        -o NumberOfPasswordPrompts=1
        -o IdentityAgent=none
        -o SendEnv=ANTHROPIC_API_KEY
        -o SendEnv=CLAUDE_CODE_OAUTH_TOKEN
        -o SendEnv=OPENAI_API_KEY
        -o SendEnv=LANG
        -o "SendEnv=LC_*"
      )

      # ── Project detection ──────────────────────────────────────────────────
      set_project_paths() {
        PROJECT_NAME="$(basename "$PROJECT_ROOT")"
        VM_NAME="sb-$PROJECT_NAME"
        VM_REPO_PATH="/home/$VM_USER/$SB_REPO_SUBDIR/$PROJECT_NAME"
      }

      find_project() {
        local dir="$PWD"
        PROJECT_ROOT=""
        while [ "$dir" != "/" ]; do
          if [ -f "$dir/.sandboxrc" ] || [ -d "$dir/.jj" ] || [ -e "$dir/.git" ]; then
            PROJECT_ROOT="$dir"
            break
          fi
          dir="$(dirname "$dir")"
        done
        if [ -z "$PROJECT_ROOT" ]; then
          PROJECT_ROOT="$PWD"
        fi
        set_project_paths
      }

      find_sandboxrc() {
        if [ -f "$PROJECT_ROOT/.sandboxrc" ]; then
          SANDBOXRC="$PROJECT_ROOT/.sandboxrc"
          return
        fi
        if [ -n "''${SB_CONFIG_PATH:-}" ]; then
          local rel="''${PROJECT_ROOT#"$HOME"/}"
          rel="''${rel#/}"
          local IFS=':'
          local dir
          for dir in $SB_CONFIG_PATH; do
            if [ -f "$dir/$rel/sandboxrc" ]; then
              SANDBOXRC="$dir/$rel/sandboxrc"
              return
            fi
          done
        fi
        SANDBOXRC=""
      }

      load_sandboxrc() {
        find_sandboxrc
        if [ -n "$SANDBOXRC" ]; then
          # shellcheck disable=SC1090,SC1091
          source "$SANDBOXRC"
        fi
        set_project_paths
      }

      # ── tart state ─────────────────────────────────────────────────────────
      vm_exists() {
        local name="''${1:-$VM_NAME}"
        tart list --format json | jq -e --arg n "$name" '.[] | select(.Name == $n)' >/dev/null 2>&1
      }

      vm_running() {
        local name="''${1:-$VM_NAME}"
        tart list --format json | jq -e --arg n "$name" '.[] | select(.Name == $n and .State == "running")' >/dev/null 2>&1
      }

      vm_ip() {
        local name="''${1:-$VM_NAME}"
        tart ip "$name"
      }

      wait_for_ip() {
        local name="''${1:-$VM_NAME}"
        info "Waiting for IP..."
        tart ip "$name" --wait 120
      }

      # ── SSH helpers ────────────────────────────────────────────────────────
      sb_ssh() {
        local ip="$1"
        shift
        sshpass -p "$VM_PASS" ssh "''${SSH_OPTS[@]}" "$VM_USER@$ip" "$@"
      }

      sb_scp() {
        sshpass -p "$VM_PASS" scp "''${SSH_OPTS[@]}" "$@"
      }

      wait_for_ssh() {
        local ip="$1"
        info "Waiting for SSH on $ip..."
        local attempts=0
        local max=60
        local last_err=""
        while true; do
          if last_err="$(sb_ssh "$ip" true 2>&1)"; then
            return 0
          fi
          attempts=$((attempts + 1))
          if [ "$attempts" -ge "$max" ]; then
            echo "sb: last ssh error was: $last_err" >&2
            err "timed out waiting for SSH on $ip"
          fi
          sleep 2
        done
      }

      # ── Host identity (read at runtime; not baked at build time) ──────────
      host_identity() {
        local name email
        name="$(git config user.name 2>/dev/null || true)"
        email="$(git config user.email 2>/dev/null || true)"
        if [ -z "$name" ] || [ -z "$email" ]; then
          err "git config user.name/user.email is not set on host"
        fi
        printf '%s\n%s\n' "$name" "$email"
      }

      setup_git_remote() {
        local ip="$1"
        export GIT_SSH_COMMAND="sshpass -p $VM_PASS ssh ''${SSH_OPTS[*]}"
        git -C "$PROJECT_ROOT" remote remove vm 2>/dev/null || true
        git -C "$PROJECT_ROOT" remote add vm "ssh://''${VM_USER}@''${ip}''${VM_REPO_PATH}"
      }

      choose_clone_source() {
        if [ -n "''${SB_VM_IMAGE:-}" ]; then
          local local_base="''${SB_VM_IMAGE##*/}"
          local_base="''${local_base%%:*}"
          if [ "$USE_REGISTRY" = false ] && vm_exists "$local_base"; then
            info "Using local $local_base image; run with --use-registry to use remote $SB_VM_IMAGE image"
            printf '%s\n' "$local_base"
          else
            info "Using remote image $SB_VM_IMAGE..."
            printf '%s\n' "$SB_VM_IMAGE"
          fi
          return
        fi

        if ! vm_exists "$BASE_IMAGE"; then
          err "base image '$BASE_IMAGE' not found. Run 'sb build-image' first."
        fi

        printf '%s\n' "$BASE_IMAGE"
      }

      # ── Commands ───────────────────────────────────────────────────────────
      cmd_build_image() {
        local force=false
        for arg in "$@"; do
          case "$arg" in
            --force|-f) force=true ;;
            *) err "unknown arg: $arg" ;;
          esac
        done

        if vm_exists "$BASE_IMAGE"; then
          if [ "$force" != true ]; then
            err "image '$BASE_IMAGE' already exists. Use --force to rebuild."
          fi
          info "Deleting existing $BASE_IMAGE..."
          tart delete "$BASE_IMAGE"
        fi

        local build_vm="sb-build-$$"
        # shellcheck disable=SC2064
        trap "tart stop '$build_vm' 2>/dev/null || true; tart delete '$build_vm' 2>/dev/null || true" EXIT

        info "Pulling $BASE_IMAGE_SOURCE..."
        tart pull "$BASE_IMAGE_SOURCE"

        info "Cloning into build VM $build_vm..."
        tart clone "$BASE_IMAGE_SOURCE" "$build_vm"
        tart set "$build_vm" --cpu 4 --memory 8192 --disk-size 40

        info "Starting build VM..."
        tart run --no-graphics "$build_vm" &
        local tart_pid=$!

        local ip
        ip="$(tart ip "$build_vm" --wait 120)"
        info "Build VM IP: $ip"

        wait_for_ssh "$ip"

        info "Copying provision script..."
        sb_scp "$SB_PROVISION_SCRIPT" "$VM_USER@$ip:/tmp/provision.sh"

        info "Running provision (this takes ~10 minutes)..."
        sb_ssh "$ip" "chmod +x /tmp/provision.sh && sudo /tmp/provision.sh"

        info "Shutting down build VM..."
        sb_ssh "$ip" "sudo shutdown -h now" || true
        wait "$tart_pid" 2>/dev/null || true

        trap - EXIT
        info "Saving as $BASE_IMAGE..."
        tart clone "$build_vm" "$BASE_IMAGE"
        tart delete "$build_vm"
        ok "Image '$BASE_IMAGE' ready."
      }

      cmd_create() {
        if vm_exists; then
          err "VM '$VM_NAME' already exists. Use 'sb destroy' or 'sb reset'."
        fi

        local clone_source
        clone_source="$(choose_clone_source)"

        info "Cloning $clone_source -> $VM_NAME..."
        tart clone "$clone_source" "$VM_NAME"
        tart set "$VM_NAME" \
          --cpu "$SB_VM_CPU" \
          --memory "$SB_VM_MEMORY" \
          --disk-size "$SB_VM_DISK"

        info "Starting VM..."
        tart run --no-graphics "$VM_NAME" &

        local ip
        ip="$(wait_for_ip)"
        info "VM IP: $ip"
        wait_for_ssh "$ip"

        local name email
        { read -r name; read -r email; } < <(host_identity)
        info "Configuring identity: $name <$email>"

        sb_ssh "$ip" "mkdir -p ~/.config/git ~/.config/jj/conf.d"

        # Build git config: [user] header (with identity) + static body.
        {
          printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email"
          cat "$SB_GIT_CONFIG"
        } | sb_ssh "$ip" "cat > ~/.config/git/config"

        # jj: static body to config.toml, identity to conf.d/identity.toml.
        sb_scp "$SB_JJ_CONFIG" "$VM_USER@$ip:/home/admin/.config/jj/config.toml"
        printf '[user]\nname = "%s"\nemail = "%s"\n' "$name" "$email" \
          | sb_ssh "$ip" "cat > ~/.config/jj/conf.d/identity.toml"

        # Suppress Claude Code onboarding.
        sb_ssh "$ip" "printf '%s\n' '{\"hasCompletedOnboarding\":true}' > ~/.claude.json"

        # Initialise an empty repo in the project path.
        local primary="''${SB_BRANCHES[0]}"
        sb_ssh "$ip" "mkdir -p $(dirname "$VM_REPO_PATH") \
          && git init --initial-branch=$primary $VM_REPO_PATH \
          && cd $VM_REPO_PATH \
          && git config receive.denyCurrentBranch updateInstead \
          && jj git init --colocate"

        if declare -f sb_provision >/dev/null 2>&1; then
          info "Running project sb_provision hook..."
          sb_provision "$ip"
        fi

        info "Injecting branches..."
        cmd_inject

        ok "Sandbox '$VM_NAME' ready. Connect with: sb ssh"
      }

      cmd_ssh() {
        local ip
        ip="$(vm_ip)" || err "VM '$VM_NAME' is not running. Try: sb start"

        local -a port_args=()
        for mapping in "''${SB_PORTS[@]+"''${SB_PORTS[@]}"}"; do
          local host_port="''${mapping%%:*}"
          local vm_port="''${mapping##*:}"
          port_args+=(-L "''${host_port}:localhost:''${vm_port}")
        done

        local -a socket_args=()
        for sock in "''${SB_SOCKETS[@]+"''${SB_SOCKETS[@]}"}"; do
          local host_sock="''${sock%%:*}"
          local vm_sock="''${sock##*:}"
          socket_args+=(-R "''${vm_sock}:''${host_sock}")
        done

        local -a cmd_args=()
        if [ $# -gt 0 ]; then
          cmd_args=("$@")
        else
          local default_exec="''${SB_SSH_EXEC:-cd ''${VM_REPO_PATH} && exec zsh -l}"
          cmd_args=(-t "$default_exec")
        fi

        exec sshpass -p "$VM_PASS" ssh "''${SSH_OPTS[@]}" \
          "''${port_args[@]+"''${port_args[@]}"}" \
          "''${socket_args[@]+"''${socket_args[@]}"}" \
          "$VM_USER@$ip" "''${cmd_args[@]+"''${cmd_args[@]}"}"
      }

      cmd_scp() {
        local ip
        ip="$(vm_ip)" || err "VM is not running"
        local -a args=()
        for arg in "$@"; do
          if [[ "$arg" == vm:* ]]; then
            args+=("$VM_USER@$ip:''${arg#vm:}")
          else
            args+=("$arg")
          fi
        done
        sb_scp "''${args[@]+"''${args[@]}"}"
      }

      cmd_start() {
        if vm_running; then
          info "VM '$VM_NAME' is already running."
          return 0
        fi
        info "Starting $VM_NAME..."
        tart run --no-graphics "$VM_NAME" &
        local ip
        ip="$(wait_for_ip)"
        wait_for_ssh "$ip"
        ok "VM '$VM_NAME' ready at $ip"
      }

      cmd_stop()    { tart stop "$VM_NAME"; }
      cmd_restart() { tart stop "$VM_NAME" 2>/dev/null || true; cmd_start; }

      cmd_destroy() {
        tart stop "$VM_NAME" 2>/dev/null || true
        tart delete "$VM_NAME" 2>/dev/null || true
        git -C "$PROJECT_ROOT" remote remove vm 2>/dev/null || true
        ok "VM '$VM_NAME' destroyed."
      }

      cmd_reset() { cmd_destroy; cmd_create; }

      cmd_status() {
        if ! vm_exists; then
          echo "VM '$VM_NAME' does not exist. Create with: sb create"
          return 0
        fi
        if vm_running; then
          echo "VM '$VM_NAME' is running."
          local ip
          if ip="$(vm_ip 2>/dev/null)"; then echo "IP: $ip"; else echo "IP: (pending)"; fi
        else
          echo "VM '$VM_NAME' exists but is stopped. Start with: sb start"
        fi
      }

      cmd_ip()   { vm_ip; }
      cmd_list() { tart list; }
      cmd_pull() {
        if [ -n "''${SB_VM_IMAGE:-}" ]; then
          info "Pulling $SB_VM_IMAGE..."
          tart pull "$SB_VM_IMAGE"
        else
          info "Pulling $BASE_IMAGE_SOURCE..."
          tart pull "$BASE_IMAGE_SOURCE"
        fi
      }

      cmd_inject() {
        local force=false
        local -a branches=()
        for arg in "$@"; do
          case "$arg" in
            --force|-f) force=true ;;
            *) branches+=("$arg") ;;
          esac
        done
        if [ ''${#branches[@]} -eq 0 ]; then
          branches=("''${SB_BRANCHES[@]}")
        fi

        local ip
        ip="$(vm_ip)" || err "VM is not running"
        setup_git_remote "$ip"

        local has_commits
        has_commits=$(sb_ssh "$ip" "cd $VM_REPO_PATH && git rev-parse HEAD >/dev/null 2>&1 && echo yes || echo no")

        if [ "$has_commits" = "yes" ]; then
          if ! sb_ssh "$ip" "cd $VM_REPO_PATH && git diff --quiet HEAD && git diff --quiet --cached" 2>/dev/null; then
            echo "Warning: VM repo has uncommitted changes."
            read -r -p "Continue anyway? [y/N] " answer
            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
              exit 1
            fi
          fi
        fi

        info "Pushing ''${branches[*]} to VM..."
        if [ "$force" = true ]; then
          git -C "$PROJECT_ROOT" push --force vm "''${branches[@]}"
        else
          if ! git -C "$PROJECT_ROOT" push vm "''${branches[@]}"; then
            echo ""
            echo "Push failed. Use 'sb inject --force' to overwrite,"
            echo "or 'sb extract' to pull VM changes first."
            exit 1
          fi
        fi

        if [ ''${#SB_WORKTREES[@]} -gt 0 ]; then
          info "Updating worktrees in VM..."
          local wt_script="cd $VM_REPO_PATH"
          for wt in "''${SB_WORKTREES[@]}"; do
            wt_script+=$'\n'"if [ -d \"$wt\" ] && git -C \"$wt\" rev-parse --git-dir &>/dev/null; then"
            wt_script+=$'\n'"  git -C \"$wt\" reset --hard \"refs/heads/$wt\""
            wt_script+=$'\n'"else"
            wt_script+=$'\n'"  git worktree add \"$wt\" \"$wt\" 2>/dev/null || true"
            wt_script+=$'\n'"fi"
          done
          sb_ssh "$ip" bash <<< "$wt_script"
        fi

        ok "Pushed: ''${branches[*]}"
      }

      cmd_extract() {
        local -a branches=("''${SB_BRANCHES[@]}")
        local ip
        ip="$(vm_ip)" || err "VM is not running"
        setup_git_remote "$ip"

        info "Fetching from VM..."
        git -C "$PROJECT_ROOT" fetch vm "''${branches[@]}"

        local has_changes=false
        for branch in "''${branches[@]}"; do
          local log
          log="$(git -C "$PROJECT_ROOT" log --oneline "$branch..vm/$branch" 2>/dev/null || true)"
          echo "$branch:"
          if [ -n "$log" ]; then
            echo "$log"
            has_changes=true
          else
            echo "  (no changes)"
          fi
          echo ""
        done

        if [ "$has_changes" = false ]; then
          ok "No changes in VM."
          return 0
        fi

        echo "To apply: sb apply"
      }

      apply_jj() {
        local -a branches=("$@")
        local jj_config='revset-aliases."immutable_heads()"="builtin_immutable_heads() ~ untracked_remote_bookmarks(remote=vm)"'

        jj git import

        local applied=false
        for branch in "''${branches[@]}"; do
          local incoming="::''${branch}@vm ~ ::''${branch}"

          if [ -z "$(jj log -r "$incoming" --no-graph -T 'change_id' 2>/dev/null)" ]; then
            continue
          fi

          info "Rebasing and signing $branch..."

          local tip
          tip=$(jj log -r "heads($incoming)" --no-graph --limit 1 -T 'change_id.shortest(8)')

          local -a change_ids=()
          while IFS= read -r cid; do
            [ -z "$cid" ] && continue
            change_ids+=("$cid")
          done < <(jj log -r "$incoming" --no-graph -T 'change_id.shortest(8) ++ "\n"')

          if ! jj rebase --config "$jj_config" -s "roots($incoming)" -d "$branch"; then
            err "rebase failed for $branch"
          fi

          for cid in "''${change_ids[@]}"; do
            jj log -r "$cid" --no-graph -T description \
              | jj describe --stdin --config "$jj_config" -r "$cid"
          done

          jj bookmark set "$branch" -r "$tip"
          applied=true
        done

        if [ "$applied" = true ]; then
          ok "Bookmarks updated. Review with 'jj log'."
        else
          ok "No changes to apply."
        fi
      }

      apply_git() {
        local -a branches=("$@")
        local applied=false
        for branch in "''${branches[@]}"; do
          local log
          log="$(git log --oneline "$branch..vm/$branch" 2>/dev/null || true)"
          if [ -z "$log" ]; then
            continue
          fi
          info "Cherry-picking and signing $branch..."

          local is_worktree=false
          for wt in "''${SB_WORKTREES[@]+"''${SB_WORKTREES[@]}"}"; do
            if [ "$wt" = "$branch" ]; then
              is_worktree=true
              break
            fi
          done

          if [ "$is_worktree" = true ]; then
            if ! git -C "$branch" cherry-pick "''${branch}..vm/''${branch}"; then
              err "cherry-pick failed for $branch in worktree $branch. Resolve, then: git cherry-pick --continue"
            fi
          else
            git checkout "$branch"
            if ! git cherry-pick "''${branch}..vm/''${branch}"; then
              err "cherry-pick failed for $branch. Resolve, then: git cherry-pick --continue"
            fi
          fi
          applied=true
        done

        if [ "$applied" = true ]; then
          ok "Branches updated. Review with 'git log'."
        else
          ok "No changes to apply."
        fi
      }

      cmd_apply() {
        local -a branches=("''${SB_BRANCHES[@]}")
        local ip
        ip="$(vm_ip)" || err "VM is not running"
        setup_git_remote "$ip"

        info "Fetching from VM..."
        git -C "$PROJECT_ROOT" fetch vm "''${branches[@]}"

        cd "$PROJECT_ROOT"
        if [ -d "$PROJECT_ROOT/.jj" ]; then
          apply_jj "''${branches[@]}"
        else
          apply_git "''${branches[@]}"
        fi
      }

      cmd_help() {
        cat <<EOF
      Usage: sb <command> [args]

      Manage sandbox VMs for isolated development with coding agents.

      Commands:
        build-image  Bake the reusable base image [--force to rebuild]
        create       Create and provision a sandbox VM for this project [--use-registry]
        ssh [cmd]    SSH into the VM; with args, runs command non-interactively
        scp          Copy files to/from VM (use vm: prefix for VM paths)
        start        Start a stopped VM
        stop         Stop the VM (preserves state)
        destroy      Stop and delete the VM
        reset        Destroy, recreate, and re-inject code [--use-registry]
        restart      Stop and restart the VM
        status       Show VM state and IP
        ip           Print VM IP address
        list         List Tart VMs and images
        inject       Push branches from host into VM [--force] [branch...]
        extract      Fetch and show VM changes
        apply        Fetch and apply VM changes to host (git cherry-pick or jj rebase+sign)
        pull         Pull the latest base image from the OCI registry
        help         Show this help

      Configuration (.sandboxrc in project root, or sandboxrc under \$SB_CONFIG_PATH):
        SB_VM_CPU       CPU cores             (default: 4)
        SB_VM_MEMORY    Memory in MiB         (default: 8192)
        SB_VM_DISK      Disk size in GB       (default: 50)
        SB_BRANCHES     Branches to sync      (default: main)
        SB_WORKTREES    Branches as worktrees (default: none)
        SB_PORTS        host:vm port forwards
        SB_SOCKETS      host_sock:vm_sock     reverse socket forwards
        SB_REPO_SUBDIR  VM home subdirectory  (default: code)
        SB_VM_IMAGE     Optional remote OCI image to clone instead of the local build
        SB_SSH_EXEC     default ssh command
        sb_provision()  post-create hook; receives VM IP as \$1

      Environment:
        SB_CONFIG_PATH  Colon-separated directories searched for sandboxrc
                        mirroring the project path relative to \$HOME

      VM:      $VM_NAME
      Project: $PROJECT_ROOT
      EOF
      }

      # ── Dispatch ───────────────────────────────────────────────────────────
      USE_REGISTRY=false
      args=()
      for arg in "$@"; do
        case "$arg" in
          --use-registry) USE_REGISTRY=true ;;
          *) args+=("$arg") ;;
        esac
      done
      set -- "''${args[@]+"''${args[@]}"}"

      find_project
      load_sandboxrc

      case "''${1:-}" in
        build-image) require_tart; shift; cmd_build_image "$@" ;;
        create)      require_tart; shift; cmd_create      "$@" ;;
        ssh)         require_tart; shift; cmd_ssh         "$@" ;;
        scp)         require_tart; shift; cmd_scp         "$@" ;;
        start)       require_tart; cmd_start ;;
        stop)        require_tart; cmd_stop ;;
        restart)     require_tart; cmd_restart ;;
        destroy)     require_tart; cmd_destroy ;;
        reset)       require_tart; cmd_reset ;;
        status)      require_tart; cmd_status ;;
        ip)          require_tart; cmd_ip ;;
        list)        require_tart; cmd_list ;;
        pull)        require_tart; cmd_pull ;;
        inject)      require_tart; shift; cmd_inject "$@" ;;
        extract)     require_tart; cmd_extract ;;
        apply)       require_tart; cmd_apply ;;
        help|--help|-h) cmd_help ;;
        "")
          require_tart
          if vm_exists; then
            cmd_ssh
          else
            echo "No VM '$VM_NAME' found. Run 'sb create' to get started."
            exit 1
          fi
          ;;
        *)
          echo "Unknown command: $1" >&2
          echo "Run 'sb help' for usage." >&2
          exit 1
          ;;
      esac
    '';
  }
