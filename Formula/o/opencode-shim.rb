class OpencodeShim < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64 (prebuilt musl binary)"
  homepage "https://github.com/anomalyco/opencode"
  url "https://registry.npmmirror.com/opencode-linux-arm64-musl/-/opencode-linux-arm64-musl-1.18.10.tgz"
  sha256 "ad67d34c1c0404a2ac33bea6d284e020a14da8a1eb2f6b14468ab22b4a1d953d"
  license "MIT"
  revision 1
  # opencode's official prebuilt linux-arm64-musl single binary (Bun --compile).
  # Bypasses the opencode-ai npm JS wrapper. The musl-ABI binary is
  # OHOS-compatible once its GCC runtime deps are provided (see resources).
  # Source mirrored on npmmirror for the same curl-SIGILL reason documented
  # in claude-code.rb; byte-identical on both mirrors.

  livecheck do
    url "https://registry.npmjs.org/opencode-ai/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-shim-v1.18.10-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62e71d499847388f44fd82ebe7d85742f5bc76fe932f397faeb8b6e43e02b26b"
  end

  # Portability design (r1-r4 archaeology is in git history): the bottle must
  # contain no HOMEBREW_PREFIX/HOMEBREW_CELLAR-shaped strings, because
  # HOMEBREW_CELLAR flips between HOMEBREW_PREFIX/Cellar and
  # HOMEBREW_REPOSITORY/Cellar depending on which exists at brew startup.
  # Hence the runtime-$HOMEBREW_PREFIX wrapper and $ORIGIN RUNPATH in
  # install(), which is also what allows :any_skip_relocation. dlopen signing
  # semantics live in the dlopen-sign-shim formula.

  # The prebuilt binary dynamically links libstdc++.so.6 + libgcc_s.so.1 (GCC
  # runtime), which OHOS does NOT ship (OHOS uses libc++). We bundle musl-aarch64
  # builds of both from Alpine and inject a DT_RUNPATH so the loader finds them.
  # OHOS ignores LD_LIBRARY_PATH, and LD_PRELOAD cannot satisfy NEEDED entries,
  # so RUNPATH (which the OHOS musl loader DOES honor) is the only mechanism.
  # patchelf rewrites segment offsets and corrupts Bun's appended module graph,
  # so RUNPATH is injected in-place (zero file-offset shift) via the
  # inject-runpath tool (its own formula in this tap).
  #
  # Additionally, the TUI extracts its embedded native modules (libopentui.so,
  # *.node, ...) to a scratch file at runtime and dlopens them. OHOS rejects
  # unsigned .so with "Permission denied" — dlopen-sign-shim (below) handles
  # this generically.
  depends_on "inject-runpath" => :build
  depends_on "ohos-bst-light" => :build
  depends_on "dlopen-sign-shim"
  depends_on "ohos-compat-shim"

  resource "libstdc++" do
    url "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64/libstdc++-15.2.0-r5.apk"
    sha256 "2302e766d4e4926038ec166ecb85837ee884576115236ddb565e3a5fca4a11d7"
  end

  resource "libgcc" do
    url "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64/libgcc-15.2.0-r5.apk"
    sha256 "369aaa6e9d099a737bad6dd3e6c2fe7bb1547ca26d22b94ee0411228f709b403"
  end

  def install
    # Guard against the binary-sign-tool auto-sign pass: it double-signs and
    # corrupts this prebuilt binary. Enforce here instead of relying on the
    # builder to remember the env dance.
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "opencode-shim must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): the " \
           "binary-sign-tool pass double-signs and corrupts this prebuilt binary"
    end

    src = buildpath.glob("package/bin/opencode").first || buildpath.glob("**/opencode").first
    odie "opencode binary not found in tarball" unless src

    libdir = libexec/"lib"
    libdir.mkpath
    sign = formula_opt_bin("ohos-bst-light")/"self-sign"

    # Deploy + sign the musl GCC runtime libraries (.apk = gzip tar).
    # Stage each resource into a Pathname target (the block form yields a
    # ResourceStageContext that does not support path division), then extract
    # the .apk if brew did not already, and copy the .so out.
    libgcc_dir = buildpath/"libgcc-rsrc"
    libstdcxx_dir = buildpath/"libstdcxx-rsrc"
    resource("libgcc").stage(libgcc_dir)
    resource("libstdc++").stage(libstdcxx_dir)

    extract_apk = lambda do |dir|
      return if (dir/"usr/lib").exist?

      apk = Dir[dir/"*.apk"].first
      system "tar", "-xzf", apk, "-C", dir.to_s if apk
    end
    extract_apk.call(libgcc_dir)
    extract_apk.call(libstdcxx_dir)

    cp libgcc_dir/"usr/lib/libgcc_s.so.1", libdir/"libgcc_s.so.1"
    real = (libstdcxx_dir/"usr/lib").glob("libstdc++.so.6.0.*").first
    odie "libstdc++.so.6 missing in apk" unless real
    # Keep the apk's own versioned name (follows Alpine bumps automatically);
    # the libstdc++.so.6 symlink provides the SONAME the binary looks up.
    cp real, libdir/real.basename
    chmod 0755, libdir/"libgcc_s.so.1"
    chmod 0755, libdir/real.basename
    system sign, (libdir/"libgcc_s.so.1").to_s
    system sign, (libdir/real.basename).to_s
    ln_sf real.basename, libdir/"libstdc++.so.6"

    # Inject DT_RUNPATH (in-place, zero offset shift) → libexec/lib.
    # Uses $ORIGIN/../lib (relative to the binary directory) instead of an
    # absolute path. The binary is at libexec/bin/opencode-shim, the bundled GCC
    # runtime libs are at libexec/lib/ — $ORIGIN/../lib resolves correctly
    # regardless of install prefix, surviving both the HOMEBREW_CELLAR flip
    # and differing HOMEBREW_PREFIX across machines. Together with the runtime
    # $HOMEBREW_PREFIX wrapper, this eliminates all HOMEBREW_PREFIX-shaped
    # strings from the bottle, allowing :any_skip_relocation.
    system formula_opt_bin("inject-runpath")/"inject-runpath", src.to_s, "$ORIGIN/../lib"

    # Self-sign the patched binary.
    system sign, src.to_s
    mkdir_p libexec/"bin"
    libexec.install src => "bin/opencode-shim"
    chmod 0755, libexec/"bin/opencode-shim"

    # Wrapper resolves all paths at runtime via $HOMEBREW_PREFIX — no build-time
    # Ruby path interpolation (see claude-code.rb for the same pattern). This
    # avoids baking the build machine's HOMEBREW_PREFIX into the script, which
    # lets `brew bottle` mark the bottle :any_skip_relocation (r1-r4
    # interpolation left prefix-shaped strings in the bottle — see the header
    # note).
    (bin/"opencode-shim").write <<~SH
      #!/bin/sh
      : "${HOMEBREW_PREFIX:?opencode-shim: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      HB="$HOMEBREW_PREFIX"
      export LD_PRELOAD="$HB/opt/dlopen-sign-shim/lib/libdlopen_sign_shim.so:$HB/opt/ohos-compat-shim/lib/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "$HB/opt/opencode-shim/libexec/bin/opencode-shim" "$@"
    SH
    chmod 0755, bin/"opencode-shim"

    # Bash completion from the binary's own yargs generator (the zsh/fish args
    # are ignored — bash-only, same as opencode.rb). The script bakes the
    # upstream CLI name (opencode — compile-time, $0-independent), so rewrite
    # it to the installed command name; otherwise bash binds the completion
    # to `opencode` instead of `opencode-shim`.
    generate_completions_from_executable(libexec/"bin/opencode-shim", "completion",
                                         shells: [:bash], base_name: "opencode-shim")
    # Identifier-anchored rewrite: covers command name, function names
    # (_opencode...), and ###-begin/end-opencode-### markers, but leaves prose
    # untouched if the generator ever emits e.g. an "opencode.ai" URL.
    inreplace bash_completion/"opencode-shim" do |s|
      s.gsub!(/(?<![a-zA-Z0-9.])opencode(?![a-zA-Z0-9.])/, "opencode-shim")
    end
  end

  def caveats
    <<~EOS
      opencode-shim (prebuilt) is ready. Configure a provider, e.g.:
        opencode-shim auth

      This build bundles musl libstdc++/libgcc_s (Alpine) and injects a
      DT_RUNPATH at them, since OHOS lacks the GCC runtime. It also preloads
      ohos-compat-shim (OHOS seccomp blocks close_range and a few other syscalls).
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode-shim --version 2>&1")
  end
end
