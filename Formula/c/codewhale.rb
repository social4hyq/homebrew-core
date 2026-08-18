class Codewhale < Formula
  desc "Local-first agent harness for DeepSeek V4 and open models"
  homepage "https://github.com/Hmbown/CodeWhale"
  url "https://github.com/Hmbown/CodeWhale/archive/refs/tags/v0.9.9.tar.gz"
  sha256 "713e1ec245147f3749eddfb49f2c04354b96a2089d83f746babd871451fd5c20"
  license "MIT"
  head "https://github.com/Hmbown/CodeWhale.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "50679f8a70af43c0021dadda261787c2d0b1e342cc89d34a5873a6904e93f6d2"
  end

  depends_on "rust" => :build

  def install
    # rquickjs-sys doesn't ship pre-built bindings for aarch64-unknown-linux-ohos.
    # Enable the bindgen feature so bindings are generated at build time.
    # The feature propagates: rquickjs/bindgen → rquickjs-core/bindgen → rquickjs-sys/bindgen.
    inreplace "Cargo.toml",
              'rquickjs = { version = "0.12", features = ["futures"] }',
              'rquickjs = { version = "0.12", features = ["futures", "bindgen"] }'

    # std_cargo_args hardcodes --locked, which would reject the Cargo.toml
    # change above.  Build args manually without --locked.
    cargo_args = ["--jobs", ENV.make_jobs.to_s, "--root=#{prefix}"]

    system "cargo", "install", *cargo_args, "--path=crates/cli"
    system "cargo", "install", *cargo_args, "--path=crates/tui"
  end

  test do
    assert_match "codewhale", shell_output("#{bin}/codewhale --version 2>&1")
  end
end
