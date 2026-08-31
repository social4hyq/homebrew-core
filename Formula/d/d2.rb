class D2 < Formula
  desc "Modern diagram scripting language that turns text to diagrams"
  homepage "https://d2lang.com/"
  url "https://github.com/d2lang/d2/archive/refs/tags/v0.8.2.tar.gz"
  sha256 "9d8b7276c9dd035233008f3a233054ecf5f3c133e89f658f759df6fe3faf6087"
  license "MPL-2.0"
  head "https://github.com/d2lang/d2.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca900cf8227ab78e5aeb57a05f42f64f679d31529d808f7eaceceed571c2bbe7"
  end

  depends_on "go" => :build

  def install
    ldflags = "-X github.com/d2lang/d2/lib/version.Version=v#{version}"
    system "go", "build", *std_go_args(ldflags:)
    man1.install "ci/release/template/man/d2.1"
  end

  test do
    test_file = testpath/"test.d2"
    test_file.write <<~EOS
      homebrew-core -> brew: depends
    EOS

    system bin/"d2", "test.d2"
    assert_path_exists testpath/"test.svg"

    assert_match "dagre is a directed graph layout algorithm implemented natively in Go by Dagro",
      shell_output("#{bin}/d2 layout dagre")

    assert_match version.to_s, shell_output("#{bin}/d2 version")
  end
end
