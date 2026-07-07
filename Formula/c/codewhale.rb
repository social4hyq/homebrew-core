class Codewhale < Formula
  desc "Local-first agent harness for DeepSeek V4 and open models"
  homepage "https://github.com/Hmbown/CodeWhale"
  url "https://github.com/Hmbown/CodeWhale/archive/refs/tags/v0.8.67.tar.gz"
  sha256 "725d177b6df1419ef1d293e83274c149bee0c4e4af307b04390586789d2025a3"
  license "MIT"
  head "https://github.com/Hmbown/CodeWhale.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "73090bbc63a53d94bdd360b5a920dac24a5ab3e0fbc527bc089cee0c3a0dfdca"
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
