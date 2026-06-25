class Gabo < Formula
  desc "Generates GitHub Actions boilerplate"
  homepage "https://github.com/ashishb/gabo"
  url "https://github.com/ashishb/gabo/archive/refs/tags/v1.12.0.tar.gz"
  sha256 "2d216d8829882d9bc4822851fa7974f1eb434fa407d1a961a6f4ef3f8bbf1fe9"
  license "Apache-2.0"
  head "https://github.com/ashishb/gabo.git", branch: "master"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b728feb9c364636aa7abb92f7828ed05930949da4841d5aa68850bd82490046d"
  end

  depends_on "go" => :build

  def install
    cd "src/gabo" do
      system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/gabo"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gabo --version")

    gabo_test = testpath/"gabo-test"
    gabo_test.mkpath
    (gabo_test/".git").mkpath # Emulate git
    system bin/"gabo", "-dir", gabo_test, "-for", "lint-yaml", "-mode=generate"
    assert_path_exists gabo_test/".github/workflows/lint-yaml.yaml"
  end
end
