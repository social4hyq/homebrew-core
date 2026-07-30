class FreshEditor < Formula
  desc "Text editor for your terminal: easy, powerful and fast"
  homepage "https://sinelaw.github.io/fresh/"
  url "https://github.com/sinelaw/fresh/archive/refs/tags/v0.4.6.tar.gz"
  sha256 "38d06554b8c825750c34ba273824590dfcb23861921b55dbd509b6efca81896e"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cf6ecaf888d625c25627dd5a45dbefde7d191ef7a44a6c17944a4367b29abb95"
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
