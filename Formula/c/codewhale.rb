class Codewhale < Formula
  desc "Local-first agent harness for DeepSeek V4 and open models"
  homepage "https://github.com/Hmbown/CodeWhale"
  url "https://github.com/Hmbown/CodeWhale/archive/refs/tags/v0.9.11.tar.gz"
  sha256 "ef934985fbb728c11aeb4b29f76f4249738d52fb2976ec6397fca788ee5d95f9"
  license "MIT"
  head "https://github.com/Hmbown/CodeWhale.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a0e38bb68c7f1b9f4d43ae188298d9fdb7d779c025c927694cfca05491a9ddf7"
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
