class VitePlus < Formula
  require "json"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v0.2.8.tar.gz"
  sha256 "c07ae8f828039fae32b791abcfc8f1d1b769024a2ae5c04bdc2946e8318615f4"
  license "MIT"
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "just" => :build
  depends_on "pnpm" => :build
  # rustup's ohos post-install needs it to rpath the downloaded cargo against
  # openssl@3 / zlib-ng-compat.
  depends_on "patchelf" => :build
  depends_on "rustup" => :build # TODO: try to restore stable rust: https://github.com/voidzero-dev/vite-task/commit/db99ba4d5d33323cc9e7b329f11bdea0610fbc7f
  depends_on "node"

  resource "rolldown" do
    url "https://github.com/rolldown/rolldown.git",
        revision: "872b98ac7476eb7d5892a2913e4ba010d124c6ac"
    version "872b98ac7476eb7d5892a2913e4ba010d124c6ac"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("rolldown", "hash")
      end
    end
  end

  resource "vite" do
    url "https://github.com/vitejs/vite.git",
        revision: "fa79f9ab699f9a22a6f9b50f3d247be6b51f684d"
    version "fa79f9ab699f9a22a6f9b50f3d247be6b51f684d"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("vite", "hash")
      end
    end
  end

  def install
    resource("rolldown").stage buildpath/"rolldown"
    resource("vite").stage buildpath/"vite"

    # pnpm >= 11.20 verifies the engine binary against the env lockfile when
    # delegating to a packageManager-pinned version; no published @pnpm/exe
    # exists for the openharmony platform. Drop the pins everywhere (vite-plus,
    # vendored rolldown and vite each declare their own) and use system pnpm
    # (same workaround as Alpine packaging).
    Dir.glob(buildpath.glob("**/package.json")).each do |path|
      # Test fixtures may contain non-strict JSON; they never drive pnpm.
      pkg = begin
        JSON.parse(File.read(path))
      rescue JSON::ParserError
        next
      end
      next unless pkg.delete("packageManager")

      File.write(path, JSON.pretty_generate(pkg) << "\n")
    end

    ENV["NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS"] = "false"
    ENV["npm_config_manage_package_manager_versions"] = "false"

    # The Aliyun rustup mirror lags upstream (ohos host artifacts for newer
    # stable pins 404) and static.rust-lang.org times out on this network;
    # the USTC mirror carries current dist artifacts at usable speed.
    ENV["RUSTUP_DIST_SERVER"] = "https://mirrors.ustc.edu.cn/rust-static"
    ENV["RUSTUP_UPDATE_ROOT"] = "https://mirrors.ustc.edu.cn/rust-static/rustup"

    # Persist the toolchain across build attempts: brew sandboxes HOME, so
    # rustup would otherwise re-download hundreds of MB every attempt.
    ENV["RUSTUP_HOME"] = (HOMEBREW_CACHE/"vite-plus-rustup").to_s

    # The downloaded cargo links libssl/libcrypto/libz; make sure they resolve
    # even when the rustup post-install rpath pass didn't run (e.g. cached
    # toolchain installed before patchelf was available).
    %w[openssl@3 zlib-ng-compat].each do |dep|
      ENV.prepend_path "LD_LIBRARY_PATH", Formula[dep].opt_lib
    end

    # Pre-install every pinned toolchain up front with retries: single
    # component downloads can still drop mid-flight; rustup keeps partial
    # files and resumes, so retries converge. Note Homebrew's system raises
    # on failure instead of returning false, hence the rescue.
    root_channel = File.read(buildpath/"rust-toolchain.toml")[/channel\s*=\s*"([^"]+)"/, 1]
    odie "no rust channel pin found in #{buildpath}/rust-toolchain.toml" if root_channel.nil?

    # Vendored sub-repos can pin older nightlies that predate ohos host
    # artifacts entirely; build everything with the root channel instead.
    buildpath.glob("**/rust-toolchain.toml").each do |file|
      channel = File.read(file)[/channel\s*=\s*"([^"]+)"/, 1]
      next if channel.nil? || channel == root_channel

      ohai "Repointing #{file} from #{channel} to #{root_channel}"
      inreplace file, /channel\s*=\s*"[^"]+"/, %(channel = "#{root_channel}")
    end

    max_attempts = 10
    toolchain = "#{root_channel}-aarch64-unknown-linux-ohos"
    (1..max_attempts).each do |attempt|
      ohai "Pre-installing rust toolchain #{toolchain} (attempt #{attempt}/#{max_attempts})"
      begin
        system "rustup", "toolchain", "install", toolchain
        break
      rescue ErrorDuringExecution
        odie "rustup failed to install #{toolchain} after #{max_attempts} attempts" if attempt == max_attempts
      end
    end

    # Direct crates.io access stalls from this network; rsproxy mirrors both
    # the sparse index and crate downloads.
    ENV["CARGO_REGISTRIES_CRATES_IO_INDEX"] = "sparse+https://rsproxy.cn/index/"

    system "just", "build"
    system "cargo", "install", *std_cargo_args(path: "crates/vite_global_cli")

    system "pnpm", "--filter=vite-plus", "deploy", "--prod", "--legacy", "--no-optional",
           prefix/"node_modules/vite-plus"
    node_modules = prefix/"node_modules/vite-plus/node_modules"
    rm_r node_modules.glob(".pnpm/*/node_modules/*/prebuilds/{darwin,ios}-x64*")
    rm_r node_modules.glob(".pnpm/fsevents@*/node_modules/fsevents")

    # Symlink vp to vpr and vpx. These are detected at runtime by argv[0]
    bin.install_symlink bin/"vp" => "vpr"
    bin.install_symlink bin/"vp" => "vpx"

    # Generate shell completions, vp uses clap but with a custom env var so we can't use our helper
    (bash_completion/"vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "bash" }, bin/"vp")
    (fish_completion/"vp.fish").write Utils.safe_popen_read({ "VP_COMPLETE" => "fish" }, bin/"vp")
    (zsh_completion/"_vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "zsh" }, bin/"vp")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vp --version")

    system bin/"vp", "create", "vite:application", "--no-interactive", "--directory", "test-app"
    assert_path_exists testpath/"test-app/package.json"

    cd testpath/"test-app" do
      output = shell_output("#{bin}/vp fmt")
      assert_match "Finished", output
    end
  end
end
