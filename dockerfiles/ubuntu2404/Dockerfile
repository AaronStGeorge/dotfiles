#===------------------------------------------------------------------------===#
# Generic Ubuntu 24.04 dev container with user matching host for bind mount
# permissions. Use `mkdevcontainer ubuntu2404 [--no-agent-configs]` to create
# the devcontainer.json for this Dockerfile.
#===------------------------------------------------------------------------===#
FROM ubuntu:24.04

# Set via .devcontainer/devcontainer.json build args
ARG USER
ARG UID
ARG GID
# Container-side path of the dotfiles repo checkout (inside the Dev/ bind
# mount); target of the ~/.dotfiles symlink created below.
ARG DOTFILES_DIR=/home/${USER}/Dev/misc/dotfiles

# Install some generally useful packages.
# bubblewrap + socat: required by Claude Code's `/sandbox` for namespace-based
# filesystem isolation and proxy-based network filtering on Linux.
RUN apt-get update && apt-get install -y \
    bash-completion \
    bubblewrap \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    cmake-curses-gui \
    curl \
    direnv \
    git \
    htop \
    jq \
    lld \
    neovim \
    ninja-build \
    nodejs \
    npm \
    openssh-client \
    python3 \
    python3-dev \
    python3-venv \
    socat \
    sudo \
    tmux \
    uidmap \
    wget

# Give bubblewrap a narrowly-scoped privileged entry point for agent sandboxes.
#
# Claude Code/Codex invoke bwrap as the non-root dev user. Docker privileged=true
# gives the container a full capability bounding set, but Linux does not hand
# those effective/permitted capabilities to an ordinary user process. In practice
# that means the dev user can start bwrap, but bwrap cannot write uid_map/gid_map,
# create nested namespaces, or configure loopback in the inner netns. We observed:
#   bwrap: setting up uid map: Permission denied
#   bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
#
# Running the whole devcontainer as root would fix that, but would make every
# command, build artifact, and bind-mounted file root-owned. The setuid bit is
# the smaller persistent escape hatch: only /usr/bin/bwrap starts with euid root,
# performs its namespace setup, then runs the requested command inside the
# sandbox. Normal shells and build commands still run as ${USER}.
#
# This is still a security-sensitive choice. A setuid-root helper increases the
# blast radius of a bwrap vulnerability, and combined with privileged=true this
# should only be used for this trusted single-user dev container.
RUN chmod 4755 /usr/bin/bwrap

# ---------------------------------------------------------------------------
# Known gap: Claude Code's sandbox needs CAP_SYS_ADMIN after bwrap drops privs
# ---------------------------------------------------------------------------
# Setuid-bwrap above is sufficient for bwrap's own work (uid_map writes, mount
# namespace setup, loopback config). It is NOT sufficient for Claude Code's
# `sandbox.enabled = true` mode (in ~/.claude/settings.json). When that is on,
# bwrap is only the first step: after bwrap finishes its privileged setup and
# drops back to ${USER}, the Claude runtime installs an additional seccomp BPF
# filter, which begins with writing "deny" to /proc/self/setgroups (lock down
# setgroups before the filter is applied). That write fails:
#
#   apply-seccomp: write /proc/self/setgroups (nested userns is capability-
#   restricted; caller must provide CAP_SYS_ADMIN): Permission denied
#
# Standard Linux userns rule: writing to /proc/self/setgroups after uid_map
# has been set up requires CAP_SYS_ADMIN in the parent userns. ${USER} has no
# caps at that point — setuid-bwrap already dropped them. The seccomp step
# happens *after* bwrap exec's into the unprivileged shell, so the setuid
# bit on bwrap doesn't help. (bwrap exposes --seccomp for exactly this case,
# but the Claude runtime does it itself in a separate post-bwrap step.)
#
# Workarounds we considered and rejected as of this writing:
#
#   - settings.json `enableWeakerNestedSandbox`: undocumented in the schema,
#     empirically does NOT bypass this specific check.
#   - pam_cap (libpam-cap + /etc/security/capability.conf): the standard
#     "give a user caps everywhere" mechanism, but pam_cap only fires for
#     PAM-authenticated sessions (ssh, login, su). VS Code Dev Containers
#     launches shells via `docker exec`, which does NOT invoke PAM, so
#     pam_cap is a silent no-op in the workflow we actually use.
#   - setcap directly on the Claude binary: scoped well, but the binary
#     lives under ~/.local/share/claude/versions/<v>/, and the auto-updater
#     replaces it (and the version dir) on each update, dropping the cap.
#     Re-applying on every update would need a root-owned post-update hook.
#   - Running the whole container as root: file-ownership problem already
#     called out in the bwrap comment above.
#
# Likely cleanest path when we revisit this — a small setcap'd C wrapper:
#
#   1. Tiny wrapper at /usr/local/bin/claude-sandboxed (system path, not
#      touched by Claude's auto-updater).
#   2. Dockerfile applies file caps:
#         setcap cap_sys_admin+eip /usr/local/bin/claude-sandboxed
#   3. Wrapper raises CAP_SYS_ADMIN into the ambient set via
#         prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_RAISE, CAP_SYS_ADMIN, 0, 0)
#      and then execve()s the real claude binary (~/.local/bin/claude).
#   4. Ambient caps propagate across exec, so Claude — and only Claude, not
#      the rest of ${USER}'s processes — holds CAP_SYS_ADMIN when it does
#      its post-bwrap setgroups write.
#
# Scope of risk: the cap stays with the Claude process for its full lifetime
# (not just sandbox setup), so the binary is effectively root-equivalent
# kernel-side. Acceptable in a single-user privileged dev container where
# ${USER} already has NOPASSWD sudo, but not a pattern to copy elsewhere.
#
# Until the wrapper is built, sandbox stays disabled in settings.json and we
# rely on Claude's auto-mode classifier (intent-level guard) for safety.

# Trust extra root CAs staged into ./certs/ — needed on networks that perform
# TLS interception (corporate proxies, e.g. AMD/Xilinx Secops).
#
# Background — how TLS verification works:
#   When `wget`/`curl` connects to e.g. dl.google.com, the server presents a
#   certificate signed by some Certificate Authority (CA). The client walks
#   the signature chain (leaf -> intermediate(s) -> root) and accepts the
#   connection only if it terminates at a root CA in its local trust store.
#   On Debian/Ubuntu that store is /etc/ssl/certs/ca-certificates.crt, built
#   from /usr/share/ca-certificates/ (the Mozilla bundle that ships with the
#   `ca-certificates` package) plus /usr/local/share/ca-certificates/ (local
#   additions), via `update-ca-certificates`.
#
# What corporate TLS interception does:
#   A middlebox sits between the container and the public internet, terminates
#   TLS on both sides, and re-presents each connection with a forged cert
#   signed by the *corporate* root CA — not by the original public CA. The
#   host machine works fine because IT has pre-installed the corporate root
#   into its trust store. A fresh container has only the Mozilla bundle and
#   has never heard of the corporate root, so wget rejects the forged cert
#   with "self-signed certificate encountered" and the build fails (typically
#   on the gh keyring or Go tarball downloads below).
#
# How to fix it for a build:
#   1. Find the corporate root CA on the host. On AMD/Xilinx machines it is
#      typically under /usr/local/share/ca-certificates/xilinx/ (look for
#      XLNX-ROOTCA.crt, AMD-ROOTCA.crt, etc.).
#   2. Copy the .crt files into this Dockerfile's ./certs/ directory.
#      `update-ca-certificates` requires PEM contents with a .crt extension
#      (Debian quirk — rename .pem to .crt if needed).
#   3. Rebuild the dev container.
#
# Outside corporate networks, ./certs/ contains only a .gitkeep sentinel,
# `update-ca-certificates` finds nothing new to add, and this is a noop. The
# staged .crt files are gitignored — they are host- and network-specific.
COPY certs/ /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Extra native build dependencies (GPU / compiler stacks, e.g. TheRock).
RUN apt-get install -y \
    automake \
    bison \
    flex \
    gdb \
    gfortran \
    git-lfs \
    libegl1-mesa-dev \
    libtool \
    patchelf \
    pkg-config \
    python3-pip \
    rsync \
    texinfo \
    unzip \
    xxd

# Install gh cli
RUN mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
	&& sudo apt install gh -y

# Install Go
ARG GO_VERSION=1.26.2
RUN wget -nv -O /tmp/go.tar.gz https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

# Create group for user matching that from host machine. Linux typically creates
# a group for each user (MacOS puts all users in group 20 "staff"), this will
# ensure that group matches up between host + container.
#   -o          : Allow non-unique GID (in case there are conflicts between host
#                 and container); given a single user dev container this is fine.
#   -g ${GID}   : Use the same Group ID as the host user
#   ${USER}     : Name the group after the user
RUN groupadd -o -g ${GID} ${USER}

# Create the user in container matching host
#   -u ${UID}    : Use the same User ID as the host user
#   -g ${USER}   : Put user in the group we just created
#   -m           : Create a home directory (/home/<USER> on Linux)
#   -s /bin/bash : Set bash as the default shell
#   ${USER}      : The username
RUN useradd -u ${UID} -g ${USER} -ms /bin/bash ${USER}

# Add user we just created to sudoers, and allow user to run sudo without a
# password. NOTE: we haven't set up a password, without NOPASSWD the user
# wouldn't be able to run sudo.
RUN usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}

# clang installs FileCheck-18; add unversioned alias for LLVM-style lit tests.
RUN ln -s /usr/lib/llvm-18/bin/FileCheck /usr/bin/FileCheck

# This is a Dockerfile variable (used in RUN commands below); shell $HOME is
# setup by Linux.
ENV HOME=/home/${USER}

# Switch to user for remaining setup.
USER ${USER}

# Suppress Ubuntu's "To run a command as administrator..." message.
RUN touch ~/.sudo_as_admin_successful

# Create .config directory so bind mounts don't create it as root.
RUN mkdir -p $HOME/.config

# Install Claude Code CLI (installs to ~/.local/bin).
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install Codex CLI (installs to ~/.local/bin to avoid root-owned /usr prefix).
RUN npm config set prefix ~/.local && npm i -g @openai/codex

# Create .dotfiles symlink (target exists after volume mount).
RUN ln -s ${DOTFILES_DIR} $HOME/.dotfiles

# Update .bashrc with common setup.
RUN cat <<'EOF' >> $HOME/.bashrc

# add stuff to path ============================================================
# agent CLIs
export PATH="$HOME/.local/bin:$PATH"
# Default Codex to the current workspace as the writable root. Launch from a
# workspace directory to keep edits inside that workspace.
alias codex='codex --sandbox workspace-write'
# dotfiles scripts
export PATH="$HOME/.dotfiles/scripts:$PATH"
# go
export PATH="/usr/local/go/bin:$PATH"

# source common bashrc from https://github.com/AaronStGeorge/dotfiles ==========
# Setup bash-completion
source /etc/profile.d/bash_completion.sh
# Eagerly load git completions (bash-completion API). Normally loads on first
# `git <tab>`, but bashrc_common needs __git_complete for aliases.
__load_completion git
if [[ -f $HOME/.dotfiles/bashrc_common ]]; then
    export WORK_APPROPRIATE_PS1=1
    source $HOME/.dotfiles/bashrc_common
fi

# direnv ======================================================================
# Hooked last so direnv wraps the final PROMPT_COMMAND (it must run after
# anything that modifies the prompt, per direnv's docs).
eval "$(direnv hook bash)"
EOF
