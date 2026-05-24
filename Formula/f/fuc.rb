class Fuc < Formula
  desc "Modern, performance focused unix commands"
  homepage "https://github.com/supercilex/fuc"
  url "https://github.com/supercilex/fuc/archive/refs/tags/3.1.1.tar.gz"
  sha256 "a26265c85d1f13fec555606a8aaa5b978d84e637de2b3cf321dd85c843339f93"
  license "Apache-2.0"
  head "https://github.com/supercilex/fuc.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afb23e9643e0508867ef2b2b21c27001c7f241e9e1420c62bdaa9f2ff01f7036"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "cpz")
    system "cargo", "install", *std_cargo_args(path: "rmz")
  end

  test do
    system bin/"cpz", test_fixtures("test.png"), testpath/"test.png"
    system bin/"rmz", testpath/"test.png"

    assert_match "cpz #{version}", shell_output("#{bin}/cpz --version")
    assert_match "rmz #{version}", shell_output("#{bin}/rmz --version")
  end
end
