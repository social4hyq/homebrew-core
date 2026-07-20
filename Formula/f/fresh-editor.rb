class FreshEditor < Formula
  desc "Text editor for your terminal: easy, powerful and fast"
  homepage "https://sinelaw.github.io/fresh/"
  url "https://github.com/sinelaw/fresh/archive/refs/tags/v0.4.4.tar.gz"
  sha256 "2573f69ae949074b7b1debf286c5890935e9d5db2eec855f997715bbd94ac8fd"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f6c9fa461242879f9ae53c419968d5369664de0e29a803832e64e9697d6d55b"
  end

  depends_on "ohos-sdk" => :build
  depends_on "rust" => :build

  # rquickjs-sys has no pre-generated bindings for OHOS (aarch64-unknown-linux-ohos),
  # so we enable the `bindgen` feature to generate them at build time.
  patch do
    file "Patches/fresh-editor/fresh-editor-ohos-bindgen.patch"
  end

  def install
    ENV["LIBCLANG_PATH"] = Formula["ohos-sdk"].opt_prefix/"native/llvm/lib"
    system "cargo", "install", *std_cargo_args(path: "crates/fresh-editor")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fresh --version")
    assert_equal "high-contrast", JSON.parse(shell_output("#{bin}/fresh --dump-config"))["theme"]
  end
end
