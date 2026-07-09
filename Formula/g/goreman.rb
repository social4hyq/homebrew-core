class Goreman < Formula
  desc "Foreman clone written in Go"
  homepage "https://github.com/mattn/goreman"
  url "https://github.com/mattn/goreman/archive/refs/tags/v0.3.19.tar.gz"
  sha256 "d5076b8844a4e29815b557927c326d8683ca4a91c8b3ffdad6fd33f238149e43"
  license "MIT"
  head "https://github.com/mattn/goreman.git", branch: "master"

  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a65d1bc62d3d27877b50f11505516f5d550470c69d6456cb6d7c7b2fbbde416e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"Procfile").write "web: echo 'hello' > goreman-homebrew-test.out"
    system bin/"goreman", "start"
    assert_path_exists testpath/"goreman-homebrew-test.out"
    assert_match "hello", (testpath/"goreman-homebrew-test.out").read
  end
end
