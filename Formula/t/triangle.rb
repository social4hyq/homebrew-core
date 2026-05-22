class Triangle < Formula
  desc "Convert images to computer generated art using Delaunay triangulation"
  homepage "https://github.com/esimov/triangle"
  url "https://github.com/esimov/triangle/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "071ba2a39b62e7914a233af74e7935ddb7a875bc2a5f193cd43862da65b1c516"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a849c84f317ee8d84957ec90a6934ee22c3b9c583827777d7be140ad103e057c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", "-mod=vendor", *std_go_args(ldflags: "-s -w"), "./cmd/triangle"
  end

  test do
    system bin/"triangle", "-in", test_fixtures("test.png"), "-out", "out.png"
    assert_path_exists testpath/"out.png"
  end
end
