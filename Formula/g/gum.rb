class Gum < Formula
  desc "Tool for glamorous shell scripts"
  homepage "https://github.com/charmbracelet/gum"
  url "https://github.com/charmbracelet/gum/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "2cbc41662ff6c8df30ff3f6c133d4276db72a6f9b3df7eb942f1a798bcbf3d80"
  license "MIT"
  compatibility_version 1
  head "https://github.com/charmbracelet/gum.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b64768dac1af9728a91f88a8090057263f26e96324251f28420aa43364ce43e4"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")

    man_page = Utils.safe_popen_read(bin/"gum", "man")
    (man1/"gum.1").write man_page

    generate_completions_from_executable(bin/"gum", "completion")
  end

  test do
    assert_match "Gum", shell_output("#{bin}/gum format 'Gum'").chomp
    assert_equal "foo", shell_output("#{bin}/gum style foo").chomp
    assert_equal "foo\nbar", shell_output("#{bin}/gum join --vertical foo bar").chomp
    assert_equal "foobar", shell_output("#{bin}/gum join foo bar").chomp
  end
end
