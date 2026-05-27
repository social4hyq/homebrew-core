class Stylua < Formula
  desc "Opinionated Lua code formatter"
  homepage "https://github.com/JohnnyMorganz/StyLua"
  url "https://github.com/JohnnyMorganz/StyLua/archive/refs/tags/v2.5.2.tar.gz"
  sha256 "26a220c7bf3a8f50d12b76c952fc4569a1162e2d002440faac3344a3634db4f2"
  license "MPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "987ce6f7662003ab6ebbe75e27f15961ac274ef3bf905a1c74991e988335f932"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", "--all-features", *std_cargo_args
  end

  test do
    (testpath/"test.lua").write("local  foo  = {'bar'}")
    system bin/"stylua", "test.lua"
    assert_equal "local foo = { \"bar\" }\n", (testpath/"test.lua").read
  end
end
