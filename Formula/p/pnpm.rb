class Pnpm < Formula
  desc "Fast, disk space efficient package manager"
  homepage "https://pnpm.io/"
  url "https://github.com/pnpm/pnpm/archive/refs/tags/v12.4.2.tar.gz"
  sha256 "2fca2c303b978c8177c13550b2d0f8e442cf32b833bea7878421f90c18a7c612"
  license "MIT"

  livecheck do
    url "https://registry.npmjs.org/pnpm/latest"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/pnpm-v12.4.2-r6"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fffcd655519159d21f061697f165ed52e1b134bc92ec2023a88c259610d5bbe0"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  # Auto-sign package-shipped ELF binaries as they enter the CAFS store;
  # node_modules hardlinks then carry the .codesign section the OHOS
  # kernel requires for exec/dlopen.
  patch do
    file "Patches/pnpm/0001-vendor-ohos-sign.patch"
  end

  patch do
    file "Patches/pnpm/0002-autosign-store-elf.patch"
  end

  patch do
    file "Patches/pnpm/0003-host-platform-openharmony.patch"
  end

  deny_network_access!

  def install
    rm ".cargo/config.toml"

    # Work around superenv breaking aws-lc-sys `-O0` needed to build CPU Jitter RNG
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
