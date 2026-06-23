class BunPty < Formula
  desc "Native shared library for HarmonyOS aarch64"
  homepage "https://github.com/sursaone/bun-pty"
  url "https://github.com/sursaone/bun-pty.git",
      tag:      "v0.4.10",
      revision: "f46192643865ab7fe7a76da63363f5d174210bfe"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-pty-v0.4.10"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da10d8b9d51837b604e2fbb7dbfab9261d0009ca9a771058b9e8a4b25e542fa7"
  end

  # portable-pty upstream source (crates.io 0.9.0). Its default nix 0.28 does not support OHOS;
  # in install we bump nix to 0.31 (nix 0.30 onwards supports *-unknown-linux-ohos,
  # see nix-rust/nix#2599/#2587/#2456). Just this one inreplace line — no need to fork the repo.
  keg_only "consumed in-tree by opencode build"

  depends_on "ohos-sdk" => :build # binary-sign-tool, only used during install
  depends_on "rust"     => :build

  resource "portable-pty" do
    url "https://static.crates.io/crates/portable-pty/0.9.0/download"
    sha256 "b4a596a2b3d2752d94f51fac2d4a96737b8705dddd311a32b9af47211f08671e"
  end

  def install
    # 1. Extract portable-pty source; glob to locate the package root
    #    (.crate may be flat or have a versioned top-level dir).
    pp_dir = buildpath/"portable-pty-src"
    pp_dir.install resource("portable-pty")
    pp_src = (pp_dir/"Cargo.toml").exist? ? pp_dir : pp_dir.glob("portable-pty-*/Cargo.toml").first&.dirname
    odie "portable-pty source not staged under #{pp_dir}" if pp_src.nil?

    # 2. Bump portable-pty's nix dependency from 0.28 to 0.31 (OHOS support).
    inreplace pp_src/"Cargo.toml", 'version = "0.28"', 'version = "0.31"'

    # 3. Repoint rust-pty/Cargo.toml's portable-pty to the source above (path dependency).
    inreplace "rust-pty/Cargo.toml" do |s|
      s.sub!(/^portable-pty\s*=.*/,
             %Q(portable-pty = { path = "#{pp_src}", features = ["serde_support"] }))
    end

    # 4. Native compile (OHOS host, rust host == aarch64-unknown-linux-ohos, no NDK/sysroot needed).
    #    superenv adaptation: the rustc_wrapper shim is #!/bin/bash but OHOS has no /bin/bash → remove it;
    #    OHOS musl has no system CA store → point cargo at a CA bundle (same as bun.rb).
    ENV.delete("RUSTC_WRAPPER")
    ENV["SSL_CERT_FILE"]  = (HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem").to_s
    ENV["CURL_CA_BUNDLE"] = ENV["SSL_CERT_FILE"]

    cd "rust-pty" do
      system "cargo", "build", "--lib", "--release", "--target", "aarch64-unknown-linux-ohos"
    end

    # 5. Sign + install
    so = buildpath/"rust-pty/target/aarch64-unknown-linux-ohos/release/librust_pty.so"
    odie "librust_pty.so build failed" unless so.exist?
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    system sign_tool, "sign", "-selfSign", "1", "-inFile", so.to_s, "-outFile", so.to_s
    chmod 0755, so
    lib.install so => "librust_pty.so"
  end

  test do
    assert_path_exists lib/"librust_pty.so"
  end
end
