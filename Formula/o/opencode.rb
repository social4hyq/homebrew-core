class Opencode < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64 (prebuilt musl binary)"
  homepage "https://github.com/anomalyco/opencode"
  url "https://registry.npmmirror.com/opencode-linux-arm64-musl/-/opencode-linux-arm64-musl-1.18.3.tgz"
  version "1.18.3"
  sha256 "3431f5cbbc1e3b0b08d23b60746d4f855ca836c0e91a91a89017f2c0e60238fe"
  license "MIT"
  revision 1
  # opencode's official prebuilt linux-arm64-musl single binary (Bun --compile).
  # Bypasses the opencode-ai npm JS wrapper. The musl-ABI binary is
  # OHOS-compatible once its GCC runtime deps are provided (see resources).
  # Source mirrored on npmmirror for the same curl-SIGILL reason as codex /
  # claude-code (see claude-code.rb); byte-identical on both mirrors.

  livecheck do
    url "https://registry.npmjs.org/opencode-ai/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.18.3-r1"
    # `brew bottle` emits `cellar: "<HOMEBREW_CELLAR>"` (not :any_skip_relocation)
    # for this formula: the RUNPATH injected into the ELF (via the
    # inject-runpath formula) is an absolute HOMEBREW_PREFIX/opt/... path, and the bottle
    # auditor flags any absolute-prefix reference in an ELF. We keep
    # :any_skip_relocation anyway — every baked reference is opt/-relative (no
    # Cellar path), the opt/<name> symlink is recreated on every pour, and
    # HOMEBREW_PREFIX is constant across build/target machines — so the bottle
    # pours identically regardless of the flat/nested HOMEBREW_CELLAR flip.
    # Verified on the real machine for r5 (1.17.20), 1.18.1, and 1.18.3.
    sha256 cellar: :any_skip_relocation, arm64_ohos: "68d49e23f3b70282faa3faa1d9703e0230a3569ef2caf6a270e1c6bdaa7f108b"
  end

  # r1 fixed a real portability bug (not just the `brew bottle` check below):
  # HOMEBREW_CELLAR flips between HOMEBREW_PREFIX/Cellar and
  # HOMEBREW_REPOSITORY/Cellar depending on which happens to exist at brew
  # startup (see brew.sh) — r0's DT_RUNPATH/wrapper baked in the Cellar-
  # absolute path from the machine that built the bottle, so pouring it on a
  # machine where HOMEBREW_CELLAR resolved the other way broke at runtime
  # ("inaccessible or not found"). Fixed by pointing RUNPATH and the wrapper's
  # self-reference at opt_libexec instead (see install() below) — opt/<name>
  # is always HOMEBREW_PREFIX-relative, so it's stable across that flip. This
  # also incidentally fixed the `brew bottle` "non-relocatable reference to
  # HOMEBREW_REPOSITORY" odie() that r0 needed a temporary bottle.rb patch to
  # get past — the RUNPATH no longer contains a HOMEBREW_REPOSITORY-shaped
  # path at all, so that check just doesn't fire anymore. Verified 2026-07-14.
  #
  # r2 fixed dlopen_sign_shim: it only signed unsigned ELFs whose path was
  # prefixed by $TMPDIR, but Bun's own extraction of embedded native modules
  # (libopentui.so etc.) does not honor our exported TMPDIR at all — observed
  # landing under /data/storage/el2/base/tmp (an OHOS-patched musl libc
  # default, independent of the TMPDIR env var) instead of the
  # /data/storage/el2/base/cache we export, so the prefix check always
  # failed and the file was never signed → "Permission denied" on dlopen.
  # r2 drops the path-prefix restriction entirely: sign any unsigned ELF
  # this process tries to dlopen, regardless of location. needs_signing()
  # already no-ops on non-ELF files and already-signed ones, and self-sign
  # failing on a file we have no business touching is silently discarded
  # (see ensure_signed), so this is safe. Also made needs_signing() fail
  # closed (attempt to sign) instead of fail open (skip signing) on
  # read/parse errors partway through the ELF, since a partially-written
  # file mid-extraction should not be silently treated as "already fine".
  # Verified 2026-07-14.
  #
  # r3 extracted dlopen_sign_shim into its own formula (dlopen-sign-shim) —
  # it's a general OHOS compatibility shim, not opencode-specific (same
  # category as ohos-bst-light in this tap), and this drops opencode's own
  # ohos-sdk :build dependency entirely since compiling the shim was the
  # only thing that needed it.
  #
  # r4: inject-runpath.py was likewise extracted into its own formula
  # (inject-runpath) — it's a general fix-prebuilt-ELF-for-OHOS tool, not
  # opencode-specific. This also moved the python@3.14 :build dep there.
  # Rebuilt with `env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN` (see
  # environment_bottle_binary_sign_breaks_prebuilt in project memory — that
  # auto-sign pass double-signs and corrupts this prebuilt binary if left
  # set during the build). Verified 2026-07-18.

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
    cp real, libdir/"libstdc++.so.6.0.34"
    chmod 0755, libdir/"libgcc_s.so.1"
    chmod 0755, libdir/"libstdc++.so.6.0.34"
    system sign, (libdir/"libgcc_s.so.1").to_s
    system sign, (libdir/"libstdc++.so.6.0.34").to_s
    ln_sf "libstdc++.so.6.0.34", libdir/"libstdc++.so.6"

    # Inject DT_RUNPATH (in-place, zero offset shift) → libexec/lib.
    # RUNPATH points at opt_libexec/lib (prefix-relative, stable), not
    # libdir/libexec (Cellar-relative). HOMEBREW_CELLAR flips between
    # HOMEBREW_PREFIX/Cellar and HOMEBREW_REPOSITORY/Cellar depending on
    # which happens to exist at brew startup (see brew.sh) — a RUNPATH baked
    # with the Cellar-absolute path breaks if poured on a machine where that
    # resolved differently than the machine it was built on. opt/<name> is
    # always HOMEBREW_PREFIX-relative and Homebrew re-links it correctly on
    # every install, so it's stable across that flip, and the dynamic linker
    # follows the opt/ symlink same as any other directory. Verified 2026-07-14.
    system formula_opt_bin("inject-runpath")/"inject-runpath", src.to_s, (opt_libexec/"lib").to_s

    # Self-sign the patched binary.
    system sign, src.to_s
    mkdir_p libexec/"bin"
    libexec.install src => "bin/opencode"
    chmod 0755, libexec/"bin/opencode"

    # Self-reference via opt_libexec (see RUNPATH comment above) rather than
    # libexec, for the same portability reason.
    (bin/"opencode").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{formula_opt_lib("dlopen-sign-shim")}/libdlopen_sign_shim.so:#{formula_opt_lib("ohos-compat-shim")}/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/opencode" "$@"
    SH
    chmod 0755, bin/"opencode"
  end

  def caveats
    <<~EOS
      opencode (prebuilt) is ready. Configure a provider, e.g.:
        opencode auth

      This build bundles musl libstdc++/libgcc_s (Alpine) and injects a
      DT_RUNPATH at them, since OHOS lacks the GCC runtime. It also preloads
      ohos-compat-shim (OHOS seccomp blocks close_range and a few other syscalls).
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version 2>&1")
  end
end
