class Tuc < Formula
  desc "Text manipulation and cutting tool"
  homepage "https://github.com/riquito/tuc"
  url "https://github.com/riquito/tuc/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "81dc5f4a0355ecdf9515c88c34c365d20f339d316df7dbe72667cd2b18445c61"
  license "GPL-3.0-or-later"
  head "https://github.com/riquito/tuc.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9008e88f7feebda111f8aad0156b3e51240ce7a7b634244bbbe6c68276512fd1"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(features: "regex")
  end

  test do
    output = pipe_output("#{bin}/tuc -e '[, ]+' -f 1,3", "a,b, c")
    assert_equal "ac\n", output
  end
end
