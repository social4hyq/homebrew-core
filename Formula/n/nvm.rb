class Nvm < Formula
  desc "Manage multiple Node.js versions (OHOS-adapted, ohos-node.com dist)"
  homepage "https://github.com/nvm-sh/nvm"
  url "https://github.com/nvm-sh/nvm/archive/refs/tags/v0.40.6.tar.gz"
  sha256 "17302cad7feedb1ad33ba738f93d2176a90970724f22de119603624fcbdec1a2"
  license "MIT"
  head "https://github.com/nvm-sh/nvm.git", branch: "master"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/nvm-v0.40.6-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01c45875e0cbadb3ca68f459e498dd544dda8edb858cb0258eb786773411eedc"
  end

  # Two OHOS adaptations applied to upstream nvm.sh:
  #   1. nvm_get_os() detects OpenHarmony via the OHOS parameter system
  #      (`param get const.ohos.version.certified`; uname is unreliable:
  #      HongMeng kernel reports "Linux", OHOS container reports "HarmonyOS")
  #   2. Default node dist mirror redirected to https://ohos-node.com/dist
  # Binaries from ohos-node.com are pre-built with the OHOS SDK toolchain
  # (aarch64-unknown-linux-ohos-clang, --dest-os=openharmony) and pre-signed
  # (.codesign section via OHOS LLD + binary-sign-tool -selfSign), so nvm's
  # stock download-checksum-extract-run flow works without any signing step.
  # Coverage: v24.2.0+ / v25 / v26 — whatever ohos-node.com publishes.
  # No v22; use nvm-ohos (brew keg redirect) or brew install node@22 for that.
  patch :p1 do
    file "Patches/nvm/0001-openharmony-support.patch"
  end

  def install
    libexec.install "nvm.sh", "nvm-exec"

    (prefix/"nvm.sh").write <<~SH
      # $NVM_DIR should be "$HOME/.nvm" by default to avoid user-installed nodes destroyed every update
      [ -z "$NVM_DIR" ] && export NVM_DIR="$HOME/.nvm"
      \\. #{opt_libexec}/nvm.sh
      # "nvm exec" and certain 3rd party scripts expect "nvm.sh" and "nvm-exec" to exist under $NVM_DIR
      [ -e "$NVM_DIR" ] || mkdir -p "$NVM_DIR"
      [ -e "$NVM_DIR/nvm.sh" ] || ln -s #{opt_libexec}/nvm.sh "$NVM_DIR/nvm.sh"
      [ -e "$NVM_DIR/nvm-exec" ] || ln -s #{opt_libexec}/nvm-exec "$NVM_DIR/nvm-exec"
    SH
    prefix.install_symlink libexec/"nvm-exec"

    # bash's `==` in POSIX `[ ]` fails under zsh's `emulate -L zsh`.
    # `=` is POSIX-standard, works in both.
    inreplace "bash_completion",
      "[ ${#COMP_WORDS[@]} == 4 ]",
      "[ ${#COMP_WORDS[@]} = 4 ]"

    # zsh gives completion functions a 1-indexed array; lookups assuming 0-indexed are off by one.
    # Wrap under ksh_arrays (0-based) via local_options (scoped, never leaks).
    inreplace "bash_completion",
      "  autoload -U +X bashcompinit && bashcompinit\nfi\n\ncomplete -o default -F __nvm nvm",
      <<~ZSH_WRAPPER.chomp
          autoload -U +X bashcompinit && bashcompinit

          __nvm_zsh_complete() {
            setopt local_options ksh_arrays
            __nvm "$@"
          }
        fi

        if [[ -n ${ZSH_VERSION-} ]]; then
          complete -o default -F __nvm_zsh_complete nvm
        else
          complete -o default -F __nvm nvm
        fi
      ZSH_WRAPPER

    # zsh's `command` can't dispatch to `cd` (special builtin).
    inreplace "bash_completion",
      'command cd "${NVM_DIR}/alias"',
      'cd "${NVM_DIR}/alias"'

    bash_completion.install "bash_completion" => "nvm"
  end

  def caveats
    <<~EOS
      This is an OHOS-adapted nvm. Upstream nvm downloads unsigned glibc
      binaries from nodejs.org that cannot run on OHOS. This formula patches
      nvm.sh to detect OpenHarmony (via musl libc) and defaults the node
      distribution mirror to https://ohos-node.com/dist — a third-party source
      of pre-built, pre-signed Node.js binaries for OpenHarmony.

      Coverage: v24.2.0+ / v25 / v26 (whatever ohos-node.com publishes).
      Use `nvm ls-remote` to browse available versions. v22 and older are
      not available; use `nvm-ohos` (brew keg redirect) or `brew install
      node@22` for those.

      You should create NVM's working directory if it doesn't exist:
        mkdir ~/.nvm

      Add the following to your shell profile e.g. ~/.profile or ~/.zshrc:
        export NVM_DIR="$HOME/.nvm"
        [ -s "#{opt_prefix}/nvm.sh" ] && \\. "#{opt_prefix}/nvm.sh"  # This loads nvm
        [ -s "#{opt_prefix}/etc/bash_completion.d/nvm" ] && \\. "#{opt_prefix}/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

      You can set $NVM_DIR to any location, but leaving it unchanged from
      #{prefix} will destroy any nvm-installed Node installations
      upon upgrade/reinstall.

      Type `nvm help` for further information.
    EOS
  end

  test do
    output = pipe_output("NODE_VERSION=homebrewtest #{prefix}/nvm-exec 2>&1")
    refute_match(/No such file or directory/, output)
    refute_match(/nvm: command not found/, output)
    assert_match "N/A: version \"homebrewtest\" is not yet installed", output

    assert_match "ohos-node.com/dist", (libexec/"nvm.sh").read
    assert_match "NVM_OS=openharmony", (libexec/"nvm.sh").read
  end
end
