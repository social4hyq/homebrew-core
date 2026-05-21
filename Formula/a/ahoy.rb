class Ahoy < Formula
  desc "Creates self documenting CLI programs from commands in YAML files"
  homepage "https://github.com/ahoy-cli/ahoy/"
  url "https://github.com/ahoy-cli/ahoy/archive/refs/tags/v2.5.0.tar.gz"
  sha256 "e57f908df16c29d5e1b5e814496d0f9eb9e11a871ed68e1fd93aa286c557c540"
  license "MIT"
  head "https://github.com/ahoy-cli/ahoy.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0fe320b03d9c66f2add5501fdeb6cf0f7a696a97849bc724bde078b330e7fc86"
  end

  depends_on "go" => :build

  def install
    cd "v2" do
      system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}-homebrew")
    end
  end

  test do
    (testpath/".ahoy.yml").write <<~YAML
      ahoyapi: v2
      commands:
        hello:
          cmd: echo "Hello Homebrew!"
    YAML
    assert_equal "Hello Homebrew!\n", shell_output("#{bin}/ahoy hello")

    assert_equal "#{version}-homebrew", shell_output("#{bin}/ahoy --version").strip
  end
end
