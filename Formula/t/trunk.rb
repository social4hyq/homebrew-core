class Trunk < Formula
  desc "Build, bundle & ship your Rust WASM application to the web"
  homepage "https://trunkrs.dev/"
  url "https://github.com/trunk-rs/trunk/archive/refs/tags/v0.21.14.tar.gz"
  sha256 "8687bcf96bdc4decee88458745bbb760ad31dfd109e955cf455c2b64caeeae2f"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/trunk-rs/trunk.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ecbb9fc3639bc6c8633ca4398b857e3de12bf8ccc652d6c9e62cf47052e8e4b"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  uses_from_macos "bzip2"

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    system "cargo", "install", *std_cargo_args
  end

  test do
    ENV["TRUNK_CONFIG"] = testpath/"Trunk.toml"
    (testpath/"Trunk.toml").write <<~TOML
      trunk-version = ">=0.19.0"

      [build]
      target = "index.html"
      dist = "dist"
    TOML

    assert_match "Configuration {\n", shell_output("#{bin}/trunk config show")

    assert_match version.to_s, shell_output("#{bin}/trunk --version")
  end
end
