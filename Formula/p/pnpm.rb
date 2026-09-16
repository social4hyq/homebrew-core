class Pnpm < Formula
  desc "Fast, disk space efficient package manager"
  homepage "https://pnpm.io/"
  url "https://github.com/pnpm/pnpm/archive/refs/tags/v12.4.2.tar.gz"
  sha256 "2fca2c303b978c8177c13550b2d0f8e442cf32b833bea7878421f90c18a7c612"
  license "MIT"

  livecheck do
    url "https://registry.npmmirror.com/pnpm/latest"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/pnpm-v12.4.2-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e47e532650cd269ddd40985f3359eb1090fc805980c812b0f52c3eeb0eba3a0d"
  end

  depends_on "cmake" => :build
  depends_on "lld@21" => :build
  depends_on "ohos-sdk" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  # Auto-sign package-shipped ELF binaries as they enter the CAFS store
  # (vendored ohos-bst-light selfsign); node_modules hardlinks then carry
  # the .codesign section the OHOS kernel requires for exec/dlopen.
  patch do
    file "Patches/pnpm/0001-vendor-ohos-sign.patch"
  end

  patch do
    file "Patches/pnpm/0002-autosign-store-elf.patch"
  end

  deny_network_access!

  def install
    rm ".cargo/config.toml"

    # aws-lc-sys cmake needs the OHOS toolchain to select the aarch64 asm
    # sources; without it ARCH detection falls back to generic and the link
    # misses every aws_lc_* crypto symbol. Jitter entropy needs -O0 that
    # superenv strips (same as upstream uv's OHOS build).
    ENV["OHOS_SDK_NATIVE"] = formula_opt_prefix("ohos-sdk")/"native"
    ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"

    system "cargo", "install", *std_cargo_args(path: "pnpm/crates/cli")

    # Upstream ships these beside the binary as shell scripts rather than
    # symlinks: the `dlx` injection for `pnpx`/`pnx` matches on the name of
    # the resolved `current_exe`, which a symlink would report as `pnpm`.
    { "pn" => [], "pnpx" => ["dlx"], "pnx" => ["dlx"] }.each do |name, args|
      (bin/name).write_env_script opt_bin/"pnpm", *args, {}
    end

    generate_completions_from_executable(bin/"pnpm", "completion")
  end

  test do
    # `pnpm init` writes a `packageManager` pin naming this exact pnpm, and
    # every later invocation resolves that pin against the registry, so
    # anything that must run without network has to come first.
    assert_match version.to_s, shell_output("#{bin}/pn --version")

    system bin/"pnpm", "init"
    assert_path_exists testpath/"package.json", "package.json must exist"
  end
end
