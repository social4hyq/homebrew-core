class Gomi < Formula
  desc "Functions like rm but with the ability to restore files"
  homepage "https://gomi.dev"
  url "https://github.com/babarot/gomi/archive/refs/tags/v1.6.4.tar.gz"
  sha256 "27d4bfca8473a5c01c3ead075f2674b47b586b6de8afc7fb31ade1c01d7e5b8a"
  license "MIT"
  head "https://github.com/babarot/gomi.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "640306c2de50db54c75525ed364ae1f7f4ae952c3bdafd73cb13fc11cb8724ab"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=v#{version}
      -X main.revision=#{tap.user}
      -X main.buildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    # Create a trash directory
    mkdir ".gomi"

    assert_match version.to_s, shell_output("#{bin}/gomi --version")

    (testpath/"trash").write <<~TEXT
      Homebrew
    TEXT

    # Restoring is done in an interactive prompt, so we only test deletion.
    assert_path_exists testpath/"trash"
    system bin/"gomi", "trash"
    refute_path_exists testpath/"trash"
  end
end
