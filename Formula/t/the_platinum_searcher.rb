class ThePlatinumSearcher < Formula
  desc "Multi-platform code-search similar to ack and ag"
  homepage "https://github.com/monochromegane/the_platinum_searcher"
  url "https://github.com/monochromegane/the_platinum_searcher/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "3d5412208644b13723b2b7ca4af0870d25c654e3a76feee846164c51b88240b0"
  license "MIT"
  head "https://github.com/monochromegane/the_platinum_searcher.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a3096d74ce03dd79d8c99d91cbcbaf16528f061dcf3c6c940a24f525459403d"
  end

  depends_on "go" => :build

  conflicts_with "tcl-tk", because: "both install `pt` binaries"

  # Patch to remove godep dependency. Remove when this is merged into release:
  # https://github.com/monochromegane/the_platinum_searcher/pull/211
  patch do
    url "https://github.com/monochromegane/the_platinum_searcher/commit/763f368fe26fa44a12e1a37598185322aa30ba8f.patch?full_index=1"
    sha256 "2ee0f53065663f22f3c44b30c5804e37b8cb49200a30c4513b9ef668441dd543"
  end

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"pt"), "./cmd/pt"
  end

  test do
    path = testpath/"hello_world.txt"
    path.write "Hello World!"

    lines = shell_output("#{bin}/pt 'Hello World!' #{path}").strip.split(":")
    assert_equal "Hello World!", lines[2]
  end
end
