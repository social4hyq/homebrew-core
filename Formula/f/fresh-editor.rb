class FreshEditor < Formula
  desc "Text editor for your terminal: easy, powerful and fast"
  homepage "https://sinelaw.github.io/fresh/"
  url "https://github.com/sinelaw/fresh/archive/refs/tags/v0.4.3.tar.gz"
  sha256 "1f417ab81c2af9f44aff53a4e7ca31053b4a93b572fb82bf49b0c30c804c6dcf"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54c32f6fce4c22ca4acf27525542a030090225a0be434ec1be89e0340f756c58"
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
