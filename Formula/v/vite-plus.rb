class VitePlus < Formula
  require "json"
  require "yaml"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2ae9ff19a0c514e55ba76f4025cead2faff67c91da7dce152c60b71a040e5192"
  license "MIT"
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  # OHOS-only blocks are fenced below; everything else tracks upstream.

  depends_on "cmake" => :build
  depends_on "just" => :build
  # OHOS: @napi-rs/cli cross-compiles the bundled bindings against the SDK.
  depends_on "ohos-sdk" => :build
  depends_on "pnpm" => :build
  depends_on "rustup" => :build # TODO: try to restore stable rust: https://github.com/voidzero-dev/vite-task/commit/db99ba4d5d33323cc9e7b329f11bdea0610fbc7f
  depends_on "node"

  resource "rolldown" do
    url "https://github.com/rolldown/rolldown.git",
        revision: "8df421985114ecfaf52cce038d4a5a6ea8c05408"
    version "8df421985114ecfaf52cce038d4a5a6ea8c05408"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("rolldown", "hash")
      end
    end
  end

  resource "vite" do
    url "https://github.com/vitejs/vite.git",
        revision: "39ddf7ccf7e7469ff6a3ba37bca38c32ea804d6e"
    version "39ddf7ccf7e7469ff6a3ba37bca38c32ea804d6e"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("vite", "hash")
      end
    end
  end

  # OHOS: vendored vite-task, for the fspy_preload_unix gate (see install).
  resource "vite-task-src" do
    url "https://github.com/voidzero-dev/vite-task.git",
        revision: "7d69d6577ecf6bd83deee32186de59918a712873"
    version "7d69d6577ecf6bd83deee32186de59918a712873"
  end

  resource "wasm-tools-linux-arm64-musl" do
    url "https://registry.npmjs.org/@napi-rs/wasm-tools-linux-arm64-musl/-/wasm-tools-linux-arm64-musl-1.1.0.tgz"
    sha256 "ebeb7f019264d53ec50392e8f550c15bf9f9b474687694c62d18119520ce93f4"
  end

  resource "lzma-linux-arm64-musl" do
    url "https://registry.npmjs.org/@napi-rs/lzma-linux-arm64-musl/-/lzma-linux-arm64-musl-1.4.5.tgz"
    sha256 "7b972be94dcada346a868a89fcd4808e93df1587d4f06666005073ffa2f62ebe"
  end

  resource "tar-linux-arm64-musl" do
    url "https://registry.npmjs.org/@napi-rs/tar-linux-arm64-musl/-/tar-linux-arm64-musl-1.1.0.tgz"
    sha256 "824ac914a4ef81cca48e97ddb2037dac318a3e0c563653c60ba2e6dfd7242f87"
  end

  # OHOS: package-manager platform-cfg (see the patch file for the rationale).
  patch :p1 do
    file "Patches/vite-plus/0001-package-manager-platform-cfg.patch"
  end

  # OHOS: managed-Node platform string (see the patch file for the rationale).
  patch :p1 do
    file "Patches/vite-plus/0002-managed-node-openharmony-platform.patch"
  end

  def install
    resource("rolldown").stage buildpath/"rolldown"
    resource("vite").stage buildpath/"vite"

    # Build with Homebrew pnpm. The staged resources pin their own versions too
    %w[package.json rolldown/package.json vite/package.json].each do |file|
      package_json = buildpath/file
      package_json.atomic_write(JSON.pretty_generate(JSON.parse(package_json.read).except("packageManager")))
    end

    # Align the staged Vite's Vitest versions with the lockfile, as upstream CI does
    system "node", "packages/tools/src/vendored-vitest.ts"

    # Vite patches only build-time dependencies, which the production deploy below omits
    (buildpath/"pnpm-workspace.yaml").append_lines "allowUnusedPatches: true"

    # --- OHOS: native bindings ----------------------------------------------
    # Two kinds of gaps, both filled by writing into pnpm-workspace.yaml:
    #   * Packages that ship their own openharmony build in-package
    #     (@ohos-npm-ports forks) are remapped in place by overrides. Being
    #     regular dependencies, they keep their binding past
    #     `deploy --no-optional`, unlike the optionalDependency grafts below.
    #   * @napi-rs/{wasm-tools,lzma,tar} publish no openharmony build, but
    #     their linux-arm64-musl twins share OHOS's libc family. The shim
    #     packages below rename the binding to what the loaders require and
    #     point `main` at it. packageExtensions adds the optionalDependency
    #     the parents don't declare; overrides remaps it to the shim.
    # Only @napi-rs/cli and @napi-rs/cross-toolchain pull these in, so the
    # shims are build-time only. Bottle signing is the pipeline's job.
    shims_dir = buildpath/"ohos-shims"
    # [parent package, version, binding file name the loaders require,
    #  Homebrew resource]
    shims = [
      ["@napi-rs/wasm-tools", "1.1.0", "wasm-tools.node", "wasm-tools-linux-arm64-musl"],
      ["@napi-rs/lzma",       "1.4.5", "lzma.node",       "lzma-linux-arm64-musl"],
      ["@napi-rs/tar",        "1.1.0", "tar.node",        "tar-linux-arm64-musl"],
    ]
    overrides = {
      "lightningcss"          => "npm:@ohos-npm-ports/lightningcss@1.33.0-1",
      # All three yuku versions have to load a binding: 0.9.3 as a prod
      # dependency of packages/core, and 0.8.7/0.10.2 at build time via
      # rolldown-plugin-dts, which packages/core/build.ts both imports and
      # reaches through tsdown. Being a devDependency only means the
      # production deploy drops it; it still has to build. Version-qualified
      # keys are required — yuku appears under several ranges in one graph.
      "yuku-codegen@0.8.7"    => "npm:@ohos-npm-ports/yuku-codegen@0.8.7-1",
      "yuku-codegen@0.9.3"    => "npm:@ohos-npm-ports/yuku-codegen@0.9.3-1",
      "yuku-codegen@0.10.2"   => "npm:@ohos-npm-ports/yuku-codegen@0.10.2-1",
      "yuku-parser@0.8.7"     => "npm:@ohos-npm-ports/yuku-parser@0.8.7-1",
      "yuku-parser@0.9.3"     => "npm:@ohos-npm-ports/yuku-parser@0.9.3-1",
      "yuku-parser@0.10.2"    => "npm:@ohos-npm-ports/yuku-parser@0.10.2-1",
      # devDependency of packages/core, but packages/core's build loads it,
      # so it needs a binding just like the yuku versions above.
      "@ast-grep/napi@0.43.0" => "npm:@ohos-npm-ports/ast-grep-napi@0.43.0-1",
      # Needed by `vp lint --type-aware`, dropped by `deploy --no-optional`
      # otherwise. Bare key: packages/cli declares it via catalog:, and
      # version-qualified selectors don't match catalog-resolved specifiers.
      "oxlint-tsgolint"       => "npm:@ohos-npm-ports/oxlint-tsgolint@7.0.2003-1",
    }
    extensions = {}
    shims.each do |parent, version, node_file, resource_name|
      ohos_name = "#{parent}-openharmony-arm64"
      shim = shims_dir/"#{parent.tr("/", "-")}-#{version}"

      shim.mkpath
      resource(resource_name).stage do
        node_src = Dir.glob("**/*.node").first
        odie "no .node in musl resource for #{parent}@#{version}" if node_src.nil?
        cp node_src, shim/node_file
      end
      (shim/"package.json").write <<~JSON
        {
          "name": "#{ohos_name}",
          "version": "#{version}",
          "main": "#{node_file}"
        }
      JSON
      extensions["#{parent}@#{version}"] = { "optionalDependencies" => { ohos_name => version } }
      overrides["#{ohos_name}@#{version}"] = "link:#{shim}"
    end
    # @parcel/watcher embeds its openharmony binding in the package itself
    # (loader falls back to that path when no platform package matches), so
    # it needs no optionalDependency graft.
    overrides["@parcel/watcher"] = "npm:@ohos-npm-ports/parcel-watcher@2.5.1-2"

    workspace_yaml = buildpath/"pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace_yaml.read)
    ws["overrides"] = overrides.merge(ws["overrides"] || {})
    ws["packageExtensions"] = extensions.merge(ws["packageExtensions"] || {})
    # The workspace's minimumReleaseAge gate (24h) blocks freshly published
    # community ports; the overrides above pin exact versions, so the pin
    # itself is the trust decision — exempt the port scope.
    ws["minimumReleaseAgeExclude"] = (ws["minimumReleaseAgeExclude"] || []).push("@ohos-npm-ports/*")
    File.write(workspace_yaml, YAML.dump(ws))
    # -------------------------------------------------------------------------

    # --- OHOS: build environment ---------------------------------------------
    # pnpm >= 11.20 verifies the engine binary for a packageManager pin, and
    # no openharmony @pnpm/exe is published.
    ENV["NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS"] = "false"
    ENV["npm_config_manage_package_manager_versions"] = "false"
    ENV.prepend_path "PATH", formula_opt_bin("pnpm")
    # Direct crates.io access stalls on some networks; probe and fall back
    # to rsproxy only where needed (fast networks keep using crates.io).
    unless system "curl", "-fsIL", "--max-time", "8", "-o", File::NULL,
                  "https://index.crates.io/config.json"
      ENV["CARGO_REGISTRIES_CRATES_IO_INDEX"] = "sparse+https://rsproxy.cn/index/"
    end
    # @napi-rs/cli builds the ohos linker/cc/ar paths from this.
    ENV["OHOS_SDK_NATIVE"] = "#{formula_opt_prefix("ohos-sdk")}/native"
    # -------------------------------------------------------------------------

    # --- OHOS: vendored vite-task ------------------------------------
    # fspy reaches fspy_preload_unix through a -Z bindeps artifact dependency
    # (artifact!("fspy_preload", ...)), so the crate has to stay in the graph
    # and keep producing its cdylib. What cannot compile here is its body:
    # the interceptions call libc::statx and execveat, which OHOS's libc has no
    # bindings for. It is already scoped out on musl, so widening the same gate
    # to ohos leaves an empty cdylib and the artifact still resolves. Only
    # this crate is patched: packages/cli stamps the vite-task toolchain node
    # with vt's cargo revision, and a [patch] entry turns a crate's source into
    # a path, which has no revision to read — build.ts then throws "Expected an
    # exact source revision for Cargo package vt". The patch stays inside the
    # staged checkout because the manifest inherits `license` from the
    # checkout's workspace root. Staged outside the workspace dir: a nested
    # workspace there derails cargo's root selection.
    vt_dir = buildpath.parent/"vite-task"
    rm_r vt_dir if vt_dir.exist?
    resource("vite-task-src").stage vt_dir
    crate = vt_dir/"crates/fspy_preload_unix"
    odie "fspy_preload_unix not found in the staged checkout" unless crate.directory?
    inreplace crate/"src/lib.rs",
              'all(unix, not(target_env = "musl"))',
              'all(unix, not(target_env = "musl"), not(target_env = "ohos"))'
    cargo_toml = buildpath/"Cargo.toml"
    File.write(cargo_toml, "#{File.read(cargo_toml)}\n" \
                           "[patch.\"https://github.com/voidzero-dev/vite-task.git\"]\n" \
                           "fspy_preload_unix = { path = \"#{crate}\" }\n")

    system "just", "build"
    system "cargo", "install", *std_cargo_args(path: "crates/vp_global_cli")

    system "pnpm", "--filter=vite-plus", "deploy", "--prod", "--legacy", "--no-optional",
           prefix/"node_modules/vite-plus"
    node_modules = prefix/"node_modules/vite-plus/node_modules"
    # Remove incompatible pre-built `bare-*` binaries. Recurse as `deploy --legacy` writes
    # both the legacy `<name>@<version>` and the current `@/<name>/<version>/<hash>` layouts
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob(".pnpm/**/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }
    rm_r node_modules.glob(".pnpm/**/node_modules/fsevents")

    # --- OHOS: bin/vp wrapper ------------------------------------------------
    # vp creates tempdirs via TMPDIR (read-only /tmp here) and its default
    # ShimMode "managed" downloads glibc Node.js binaries OHOS won't exec.
    # write_env_script cannot express "default TMPDIR if unset" or
    # first-run config seeding, hence the wrapper. The real binary sits one
    # level below prefix so <dir>/../node_modules still resolves.
    odie "cargo install did not produce bin/vp" unless (bin/"vp").exist?
    libexec.mkpath
    mv bin/"vp", libexec/"vp"
    (bin/"vp").write <<~SH
      #!/bin/sh
      TMPDIR_DEFAULT="#{HOMEBREW_PREFIX}/var/cache"
      export TMPDIR="${TMPDIR:-$TMPDIR_DEFAULT}"
      mkdir -p "$TMPDIR" 2>/dev/null
      if [ -n "$HOME" ] && [ ! -f "$HOME/.vite-plus/config.json" ]; then
        mkdir -p "$HOME/.vite-plus" 2>/dev/null &&
          printf '{"shimMode":"system_first"}\\n' > "$HOME/.vite-plus/config.json" 2>/dev/null
      fi
      exec "#{libexec}/vp" "$@"
    SH
    chmod 0755, bin/"vp"
    # ----------------------------------------------------------------------

    # Symlink vp to vpr and vpx. These are detected at runtime by argv[0]
    bin.install_symlink bin/"vp" => "vpr"
    bin.install_symlink bin/"vp" => "vpx"

    # Generate shell completions, vp uses clap but with a custom env var so we can't use our helper
    (bash_completion/"vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "bash" }, bin/"vp")
    (fish_completion/"vp.fish").write Utils.safe_popen_read({ "VP_COMPLETE" => "fish" }, bin/"vp")
    (zsh_completion/"_vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "zsh" }, bin/"vp")
  end

  def caveats
    <<~EOS
      On OHOS, /tmp is read-only and vp's Rust install path creates tempdirs
      via TMPDIR. bin/vp is a wrapper that defaults TMPDIR to
      #{HOMEBREW_PREFIX}/var/cache when unset.

      vp's default ShimMode is "managed" (downloads official glibc Node.js
      binaries that OHOS refuses to exec). The wrapper seeds
      ~/.vite-plus/config.json with {"shimMode":"system_first"} on first
      run, so the system Node.js is preferred; delete that file to opt
      back into managed runtimes.
    EOS
  end

  test do
    # OHOS: /tmp is read-only, and HOME must point at testpath so the
    # wrapper's first-run config seeding lands here
    ENV["TMPDIR"] = testpath/"tmp"
    mkdir_p ENV["TMPDIR"]
    ENV["HOME"] = testpath.to_s

    # Use Homebrew node and skip the first-run setup prompt, which stops `vp` on the test PTY
    ENV["VP_NODE_MANAGER"] = "no"

    assert_match version.to_s, shell_output("#{bin}/vp --version")

    # `vp` calls `tcsetattr` on a tty stdin, which stops it with SIGTTOU on the test PTY
    system "#{bin}/vp create vite:application --no-interactive --directory test-app < /dev/null"
    assert_path_exists testpath/"test-app/package.json"

    # OHOS: the scaffolded app resolves vite-plus from the npm registry, which
    # ships no openharmony bindings. Wire it the way an end user would —
    # override to the @ohos-npm-ports port (its binding ships signed), graft the
    # @rolldown openharmony binding onto the registry vite-plus-core, sign what
    # pnpm fetched unsigned, and drop the scaffold's `prepare: vp config` hook,
    # which runs before install can fetch bindings. The scaffold's workspace
    # file already has an overrides section, so merge into it.
    pkg_json = testpath/"test-app/package.json"
    manifest = JSON.parse(pkg_json.read)
    manifest["scripts"].delete("prepare")
    manifest["devDependencies"] ||= {}
    manifest["devDependencies"]["ohos-signpost"] = "^1.0.2"
    manifest["scripts"]["postinstall"] = "ohos-signpost"
    File.write(pkg_json, JSON.pretty_generate(manifest) << "\n")

    # The port is not on npm yet (ohos-npm-ports#72 is unmerged), so take the
    # tarball the fork's CI published to its release instead. Reachable without
    # credentials, unlike a workflow artifact. Once the port reaches npm this
    # becomes "npm:@ohos-npm-ports/vite-plus@1.0.0-1" and the download goes away.
    port_tarball = testpath/"vite-plus-ohos-port.tgz"
    port_url = "https://github.com/social4hyq/ohos-npm-ports/releases/download/vite-plus-1.0.0/" \
               "ohos-npm-ports-vite-plus-1.0.0-1.tgz"
    system "curl", "-fsSL", "--retry", "3", "--retry-all-errors", "-o", port_tarball, port_url
    # Read the archive rather than just checking it exists: a failed or truncated
    # download installs a package with no binding and then fails with a
    # confusing "Cannot find native binding" that points nowhere near the cause.
    begin
      entries = []
      Zlib::GzipReader.open(port_tarball) do |gz|
        Gem::Package::TarReader.new(gz) { |tar| tar.each { |e| entries << e.full_name } }
      end
    rescue Zlib::Error, Gem::Package::FormatError => e
      odie "port tarball is not a readable gzip (#{e.class})"
    end
    odie "port tarball carries no package.json" unless entries.include?("package/package.json")
    odie "port tarball carries no binding" unless entries.any? do |e|
      e.end_with?("vite-plus.openharmony-arm64.node")
    end

    workspace = testpath/"test-app/pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace.read)
    ws["overrides"] = {
      "vite-plus" => "file:#{port_tarball}",
    }.merge(ws["overrides"] || {})
    ws["packageExtensions"] = {
      "@voidzero-dev/vite-plus-core@1.0.0" => {
        "optionalDependencies" => { "@rolldown/binding-openharmony-arm64" => "1.2.11" },
      },
    }.merge(ws["packageExtensions"] || {})
    # OHOS: the graft above only matters if pnpm treats the openharmony
    # optional package as installable. `vp`'s package manager is a standalone
    # native pnpm executable (see Patches/vite-plus/0001-…patch) with no
    # Node.js involved, so it cannot know it runs on openharmony and silently
    # prunes the optional dependency as a platform mismatch. Force it in via
    # supportedArchitectures, the standard pnpm escape hatch.
    ws["supportedArchitectures"] = {
      "os" => ["current", "openharmony"],
    }.merge(ws["supportedArchitectures"] || {})
    File.write(workspace, YAML.dump(ws))

    vp_with_retry = lambda do |*args|
      max_attempts = 3
      (1..max_attempts).each do |attempt|
        system bin/"vp", *args
        break
      rescue BuildError => e
        msg = e.message.to_s.lines.last(5).join
        odie "vp #{args.first} failed (#{e.class}):\n#{msg}" if attempt == max_attempts
        sleep 10
      end
    end

    vp_with_retry.call "install"

    cd testpath/"test-app" do
      output = shell_output("#{bin}/vp fmt < /dev/null")
      assert_match "Finished", output
    end
  end
end
