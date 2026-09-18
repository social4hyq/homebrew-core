class Railway < Formula
  desc "Develop and deploy code with zero configuration"
  homepage "https://railway.com/"
  url "https://github.com/railwayapp/cli/archive/refs/tags/v5.57.9.tar.gz"
  sha256 "b38f6da300abe910c5081b89177369739e6f257bb86de444b768e8617536855a"
  license "MIT"
  head "https://github.com/railwayapp/cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51ec22227c6b62f4c6167d98049334ff55be928c6c4ac0316e0d13a9e8eb6098"
  end

  depends_on "rust" => :build

  def install
    # nix 0.25.1 (via portable-pty, which pins nix = "0.25") does not support
    # the OHOS target (aarch64-unknown-linux-ohos): libc treats target_env =
    # "ohos" as musl, but nix 0.25.1 only excludes target_env = "musl", so it
    # references symbols that libc does not provide on OHOS. Patch nix to
    # treat OHOS like musl (same fix as upstream nix >= 0.30, cf.
    # https://github.com/nix-rust/nix/pull/2587). The vendored path and patch
    # file are version-specific (nix 0.25.1, pinned by portable-pty): update
    # them together if the nix version ever changes.
    #
    # Vendor the dependency tree and make cargo fetch from vendor/.
    system "cargo", "vendor", "--locked", "--versioned-dirs", "vendor"
    (buildpath/".cargo").mkpath
    File.write(buildpath/".cargo/config.toml", <<~EOS)
      [source.crates-io]
      replace-with = "vendored-sources"

      [source.vendored-sources]
      directory = "vendor"
    EOS
    # Patch nix for OHOS and mount it via [patch.crates-io] (a path source, so
    # cargo skips .cargo-checksum.json verification), then sync Cargo.lock.
    system "patch", "-p1", "-d", "vendor/nix-0.25.1",
           "-i", tap.path/"Patches/railway/0001-nix-0.25.1-ohos.patch"
    File.write(buildpath/"Cargo.toml", <<~EOS, mode: "a")
      [patch.crates-io]
      nix = { path = "vendor/nix-0.25.1" }
    EOS
    system "cargo", "update", "-p", "nix@0.25.1"

    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"railway", "completion")
  end

  test do
    output = shell_output("#{bin}/railway init 2>&1", 1).chomp
    assert_match "Unauthorized. Please login with `railway login`", output

    assert_equal "railway #{version}", shell_output("#{bin}/railway --version").strip
  end
end
