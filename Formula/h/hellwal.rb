class Hellwal < Formula
  desc "Fast, extensible color palette generator"
  homepage "https://github.com/danihek/hellwal"
  url "https://github.com/danihek/hellwal/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "78cea94425b35a4dc377e498921ddb2927b093ed6b825606554f25b98699310c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "76d06b8c261a73e1582a59107f7b4f5bc2abba668661b59744b6ae1cb5cf551c"
  end

  def install
    system "make", "install", "DESTDIR=#{bin}"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hellwal --version")

    (testpath/"hw.theme").write "%% color0  = #282828 %%"
    output = shell_output("#{bin}/hellwal --skip-term-colors -j -t hw.theme 2>&1", 1)
    assert_match "Not enough colors were specified in color palette", output
  end
end
