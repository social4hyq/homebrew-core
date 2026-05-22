class Xc < Formula
  desc "Markdown defined task runner"
  homepage "https://xcfile.dev/"
  url "https://github.com/joerdav/xc/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "afcb5e1fbd1be5f0b6dcb802e02c96527ac0e96ddeb47471b8ad4056f91ccc72"
  license "MIT"
  head "https://github.com/joerdav/xc.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec8e7697b03859fffadc170a01abf8bebdf54e07aebc71fbb0f660f5ae17f201"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/xc"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xc --version")

    (testpath/"README.md").write <<~MARKDOWN
      # Tasks

      ## hello
      ```sh
      echo "Hello, world!"
      ```
    MARKDOWN

    output = shell_output("#{bin}/xc hello")
    assert_match "Hello, world!", output
  end
end
