class FreshEditor < Formula
  desc "Text editor for your terminal: easy, powerful and fast"
  homepage "https://sinelaw.github.io/fresh/"
  url "https://github.com/sinelaw/fresh/archive/refs/tags/v0.4.10.tar.gz"
  sha256 "a315a38f0598554998e7b256d4ef997d158592532d43ca52328c8dc8e177d65f"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c962c8aa3ecbb37eb759ebac09b2ebedfc61e2d3488a85e7c42f7e7fa8e1ae8e"
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
