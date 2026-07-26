class OpencodeAT2 < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64 (v2 preview, prebuilt)"
  homepage "https://github.com/anomalyco/opencode"
  # v2's prebuilt platform binary (@opencode-ai/cli-linux-arm64-musl) has not
  # synced onto registry.npmmirror.com as of this writing (the scope package
  # @opencode-ai/cli itself is mirrored; this per-platform subpackage isn't,
  # even after triggering an on-demand sync) — falls back to
  # registry.npmjs.org directly, same as the SIGILL-on-large-GET reason
  # documented for claude-code/codex (only affects local machine curl, not
  # bottle distribution or the CI runner that builds it).
  url "https://registry.npmjs.org/@opencode-ai/cli-linux-arm64-musl/-/cli-linux-arm64-musl-0.0.0-next-16231.tgz"
  version "0.0.0-next-16231"
  sha256 "a0f9109a6dd77ab994f338ad1246117882754cb5dfe1a20ac3c35daf8b057bba"
  license "MIT"
  # opencode v2's official prebuilt linux-arm64-musl single binary (Bun
  # --compile, bin name changed from `opencode` to `opencode2`). Bypasses the
  # @opencode-ai/cli npm JS wrapper. Same musl-ABI-compatible-with-OHOS
  # premise as opencode.rb (v1) — verified: readelf -d on the extracted
  # binary shows the identical NEEDED set (libstdc++.so.6,
  # libc.musl-aarch64.so.1, libgcc_s.so.1), no RUNPATH, no .codesign section,
  # so v1's whole treatment (RUNPATH injection + bundled musl GCC runtime +
  # self-sign + dlopen-sign-shim/ohos-compat-shim wrapper) applies unchanged.

  livecheck do
    url "https://registry.npmmirror.com/@opencode-ai/cli/next"
    regex(/"version":\s*"([^"]+)"/i)
  end

  # The prebuilt binary dynamically links libstdc++.so.6 + libgcc_s.so.1 (GCC
  # runtime), which OHOS does NOT ship (OHOS uses libc++). We bundle musl-aarch64
  # builds of both from Alpine and inject a DT_RUNPATH so the loader finds them.
  # OHOS ignores LD_LIBRARY_PATH, and LD_PRELOAD cannot satisfy NEEDED entries,
  # so RUNPATH (which the OHOS musl loader DOES honor) is the only mechanism.
  # patchelf rewrites segment offsets and corrupts Bun's appended module graph,
  # so RUNPATH is injected in-place (zero file-offset shift) via the
  # inject-runpath tool (its own formula in this tap).
  #
  # The TUI also extracts its embedded native modules (libopentui.so, *.node,
  # ...) to a scratch file at runtime and dlopens them. OHOS rejects unsigned
  # .so with "Permission denied" — dlopen-sign-shim (below) handles this
  # generically.
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
    # Guard against the auto-sign pass corrupting this prebuilt binary — see
    # environment_bottle_binary_sign_breaks_prebuilt: double-signing a
    # prebuilt ELF makes it exit 139. Enforce here instead of relying on the
    # builder to remember the env dance (build.sh's UNSET_SIGN_FORMULAS is
    # the CI-side half of this same guard).
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "opencode@2 must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): the " \
           "binary-sign-tool pass double-signs and corrupts this prebuilt binary"
    end

    src = buildpath.glob("package/bin/opencode2").first || buildpath.glob("**/opencode2").first
    odie "opencode2 binary not found in tarball" unless src

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
    # libdir/libexec (Cellar-relative) — opt/<name> is always
    # HOMEBREW_PREFIX-relative and Homebrew re-links it correctly on every
    # install, so it stays stable across the HOMEBREW_CELLAR flat/nested flip
    # (see opencode.rb's r1 history for why that distinction matters).
    system formula_opt_bin("inject-runpath")/"inject-runpath", src.to_s, (opt_libexec/"lib").to_s

    # Self-sign the patched binary.
    system sign, src.to_s
    mkdir_p libexec/"bin"
    libexec.install src => "bin/opencode2"
    chmod 0755, libexec/"bin/opencode2"

    # Self-reference via opt_libexec (see RUNPATH comment above) rather than
    # libexec, for the same portability reason.
    (bin/"opencode2").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{formula_opt_lib("dlopen-sign-shim")}/libdlopen_sign_shim.so:#{formula_opt_lib("ohos-compat-shim")}/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{opt_libexec}/bin/opencode2" "$@"
    SH
    chmod 0755, bin/"opencode2"
  end

  def caveats
    <<~EOS
      opencode2 (v2 preview, prebuilt) is ready. Configure a provider, e.g.:
        opencode2 auth

      This is the "next" channel preview of opencode v2 — expect frequent,
      unannounced breaking changes upstream. It installs alongside `opencode`
      (v1, stable) without conflict: different binary name (opencode2), no
      shared files.

      This build bundles musl libstdc++/libgcc_s (Alpine) and injects a
      DT_RUNPATH at them, since OHOS lacks the GCC runtime. It also preloads
      ohos-compat-shim (OHOS seccomp blocks close_range and a few other syscalls).
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
