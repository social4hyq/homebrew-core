class Minica < Formula
  desc "Small, simple certificate authority"
  homepage "https://github.com/jsha/minica"
  url "https://github.com/jsha/minica/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "4f56ea73d2a943656f8a5b533e554b435bc10f56c12d0b53836e84a96b513bf7"
  license "MIT"
  head "https://github.com/jsha/minica.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "05700d52d0c58d55ba8974fb7e3aaaaf85d6dedb02e8468c6ede188dabc6587e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    system bin/"minica", "--domains", "foo.com"
    assert_path_exists testpath/"minica.pem"
  end
end
