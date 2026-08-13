class NvmOhos < Formula
  desc "OHOS-adapted nvm: manage multiple Node.js versions via brew node kegs"
  homepage "https://github.com/nvm-sh/nvm"
  url "https://github.com/nvm-sh/nvm/archive/refs/tags/v0.40.6.tar.gz"
  sha256 "17302cad7feedb1ad33ba738f93d2176a90970724f22de119603624fcbdec1a2"
  license "MIT"
  revision 3

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/nvm-ohos-v0.40.6-r6"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "268e572204f49897a99fcfb2500764f501fbbce87acecb075f5e51f0773c898c"
  end

  # Upstream nvm downloads unsigned glibc binaries that can't run on OHOS.
  # This formula does NOT patch nvm.sh (kept byte-for-byte); instead installs nvm-ohos.sh
  # that plugs into nvm's $NVM_INSTALL_THIRD_PARTY_HOOK to redirect to brew-built kegs.
  # unofficial-builds.nodejs.org musl spike rejected: dynamic libgcc_s.so.1 dependency.
  # Coverage: node@22/24/26 only.
  def install
    libexec.install "nvm.sh", "nvm-exec"

    (libexec/"nvm-ohos.sh").write <<~SH
      # nvm-ohos adapter: source AFTER nvm.sh, in the same shell.
      #
      # Redirects `nvm install <major>` to `brew install node@<major>` (or
      # bare `node`, aliased to the current major by the tap) and wires the
      # resulting keg into nvm's version directory — instead of letting nvm
      # fetch an upstream binary that cannot run here.
      #
      # Opt out entirely with NVM_OHOS_DISABLE=1 (falls back to stock nvm
      # behavior, which will not produce a runnable node on this OS).

      nvm_ohos_materialize_keg() {
        local KEG_DIR="$1"
        local VERSION_PATH="$2"

        if [ -x "${VERSION_PATH}/bin/node" ]; then
          return 0
        fi

        command mkdir -p "${VERSION_PATH}/bin" || return 1
        # Real copy, not symlink: node resolves process.execPath via /proc/self/exe which follows
        # symlinks back to the brew keg, making npm's default prefix wrong. Signature survives copy.
        command cp "${KEG_DIR}/bin/node" "${VERSION_PATH}/bin/node" || return 1
        command chmod +x "${VERSION_PATH}/bin/node" || return 1

        local d
        for d in include share; do
          if [ -d "${KEG_DIR}/${d}" ]; then
            command ln -sfn "${KEG_DIR}/${d}" "${VERSION_PATH}/${d}"
          fi
        done

        # npm location varies: node@N puts it at lib/node_modules, bare node at libexec/lib.
        local NPM_SRC=""
        if [ -d "${KEG_DIR}/lib/node_modules/npm" ]; then
          NPM_SRC="${KEG_DIR}/lib/node_modules/npm"
        elif [ -d "${KEG_DIR}/libexec/lib/node_modules/npm" ]; then
          NPM_SRC="${KEG_DIR}/libexec/lib/node_modules/npm"
        fi

        if [ -n "${NPM_SRC}" ]; then
          command mkdir -p "${VERSION_PATH}/lib/node_modules" || return 1
          command cp -R "${NPM_SRC}" "${VERSION_PATH}/lib/node_modules/npm" || return 1

          # Strip prefix/globalconfig lines from our npmrc copy only: nvm checks npmrc on every
          # `nvm use` and refuses (exit 10) if it finds a prefix line. With bin/node as a real copy,
          # npm's execPath-derived default prefix is already correct without override.
          local NPMRC="${VERSION_PATH}/lib/node_modules/npm/npmrc"
          if [ -f "${NPMRC}" ]; then
            command sed -E -i '/^[[:space:]]*(prefix|globalconfig)[[:space:]]*=/d' "${NPMRC}"
          fi

          command ln -sfn "../lib/node_modules/npm/bin/npm-cli.js" "${VERSION_PATH}/bin/npm"
          command ln -sfn "../lib/node_modules/npm/bin/npx-cli.js" "${VERSION_PATH}/bin/npx"
        else
          nvm_err "nvm-ohos: warning: no npm found under ${KEG_DIR}, installed node without npm/npx"
        fi

        if [ ! -x "${VERSION_PATH}/bin/node" ]; then
          nvm_err "nvm-ohos: materialize failed, ${VERSION_PATH}/bin/node is not executable"
          return 1
        fi

        return 0
      }

      nvm_ohos_third_party_hook() {
        local VERSION="$1"
        local FLAVOR="$2"
        local VERSION_PATH="$5"

        if [ "${FLAVOR}" != 'node' ]; then
          nvm_err "nvm-ohos: only the 'node' flavor is supported (got '${FLAVOR}')"
          return 1
        fi

        local MAJOR
        MAJOR="$(nvm_echo "${VERSION}" | command sed -E 's/^v?([0-9]+).*/\\1/')"
        if [ -z "${MAJOR}" ]; then
          nvm_err "nvm-ohos: cannot parse a major version out of '${VERSION}'"
          return 1
        fi

        local BREW_FORMULA="node@${MAJOR}"
        if ! brew info "${BREW_FORMULA}" >/dev/null 2>&1; then
          local AVAILABLE
          AVAILABLE="$(brew search '/^node@[0-9]+$/' 2>/dev/null | command tr '\\n' ' ')"
          nvm_err "nvm-ohos: no OHOS build for Node ${MAJOR}.x. Available majors: ${AVAILABLE:-none}"
          return 1
        fi

        if ! brew list --versions "${BREW_FORMULA}" >/dev/null 2>&1; then
          nvm_echo "nvm-ohos: installing ${BREW_FORMULA} via brew..."
          brew install "${BREW_FORMULA}" || {
            nvm_err "nvm-ohos: brew install ${BREW_FORMULA} failed"
            return 1
          }
        fi

        local BREW_VERSION
        BREW_VERSION="$(brew list --versions "${BREW_FORMULA}" | command awk '{print $2}')"
        if [ -z "${BREW_VERSION}" ]; then
          nvm_err "nvm-ohos: cannot determine the installed version of ${BREW_FORMULA}"
          return 1
        fi

        local KEG_DIR
        KEG_DIR="$(brew --cellar "${BREW_FORMULA}")/${BREW_VERSION}"
        if [ ! -d "${KEG_DIR}" ]; then
          nvm_err "nvm-ohos: expected keg not found at ${KEG_DIR}"
          return 1
        fi

        if [ "v${BREW_VERSION}" != "${VERSION}" ]; then
          nvm_err "nvm-ohos: nodejs.org has ${VERSION}, this tap currently builds ${BREW_FORMULA} ${BREW_VERSION} — using that instead"
        fi

        nvm_ohos_materialize_keg "${KEG_DIR}" "${VERSION_PATH}" || return 1

        # Also make the exact "vX.Y.Z" brew version resolvable, in case it
        # differs from the (possibly newer) version nvm resolved from
        # nodejs.org above.
        local REAL_VERSION_PATH
        REAL_VERSION_PATH="$(nvm_version_path "v${BREW_VERSION}")"
        if [ "${REAL_VERSION_PATH}" != "${VERSION_PATH}" ] && [ ! -e "${REAL_VERSION_PATH}" ]; then
          command mkdir -p "$(command dirname "${REAL_VERSION_PATH}")" 2>/dev/null
          command ln -sfn "${VERSION_PATH}" "${REAL_VERSION_PATH}"
        fi

        return 0
      }

      if [ "${NVM_OHOS_DISABLE-}" != '1' ]; then
        export NVM_INSTALL_THIRD_PARTY_HOOK="nvm_ohos_third_party_hook"
      fi
    SH

    (prefix/"nvm.sh").write <<~SH
      # $NVM_DIR should be "$HOME/.nvm" by default to avoid user-installed nodes destroyed every update
      [ -z "$NVM_DIR" ] && export NVM_DIR="$HOME/.nvm"
      \\. #{opt_libexec}/nvm.sh
      \\. #{opt_libexec}/nvm-ohos.sh
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

          __nvm_ohos_zsh_complete() {
            setopt local_options ksh_arrays
            __nvm "$@"
          }
        fi

        if [[ -n ${ZSH_VERSION-} ]]; then
          complete -o default -F __nvm_ohos_zsh_complete nvm
        else
          complete -o default -F __nvm nvm
        fi
      ZSH_WRAPPER

    # zsh's `command` can't dispatch to `cd` (special builtin).
    inreplace "bash_completion",
      'command cd "${NVM_DIR}/alias"',
      'cd "${NVM_DIR}/alias"'

    bash_completion.install "bash_completion" => "nvm-ohos"
  end

  def caveats
    <<~EOS
      This is an OHOS-adapted nvm: `nvm install <major>` installs via
      `brew install node@<major>` (or the bare "node" formula, whichever
      this tap currently aliases to that major) instead of downloading an
      upstream binary — those are unsigned glibc builds that cannot run on
      this OS. Coverage is therefore limited to whatever node/node@N
      formulas this tap builds today (`brew search '/^node@[0-9]+$/'` to
      list them) — currently 22, 24, 26. `nvm install 20` and older will
      fail with a clear error rather than installing a broken binary.

      Do not point $NVM_DIR at a directory shared with harmonybrew/core's
      unmodified "nvm" formula — that one has no OHOS adaptation and will
      write unusable version directories into the same tree.

      You should create NVM's working directory if it doesn't exist:
        mkdir ~/.nvm

      Add the following to your shell profile e.g. ~/.profile or ~/.zshrc:
        export NVM_DIR="$HOME/.nvm"
        [ -s "#{opt_prefix}/nvm.sh" ] && \\. "#{opt_prefix}/nvm.sh"  # This loads nvm (+ the OHOS adapter)
        [ -s "#{opt_prefix}/etc/bash_completion.d/nvm-ohos" ] && \\. "#{opt_prefix}/etc/bash_completion.d/nvm-ohos"  # This loads nvm bash_completion

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

    (testpath/"test.sh").write <<~SH
      export NVM_DIR="#{testpath}/.nvm"
      mkdir -p "$NVM_DIR"
      \\. #{libexec}/nvm.sh
      \\. #{libexec}/nvm-ohos.sh
      type nvm_ohos_third_party_hook >/dev/null 2>&1 || exit 1
      [ "$NVM_INSTALL_THIRD_PARTY_HOOK" = "nvm_ohos_third_party_hook" ] || exit 1
    SH
    system "bash", testpath/"test.sh"
  end
end
