class Mkbrr < Formula
  desc "Is a tool to create, modify and inspect torrent files. Fast"
  homepage "https://mkbrr.com/introduction"
  url "https://github.com/autobrr/mkbrr/archive/refs/tags/v1.25.1.tar.gz"
  sha256 "b6e7e1e1eb9ff9b730ad271e6d22dba298d13700fa46cc69da687a7c5ad47042"
  license "GPL-2.0-or-later"
  head "https://github.com/autobrr/mkbrr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1e7ef8c26dba83c6fd9e2211513235f82e5a48b2518032393cb06f60c467b4bc"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version} -X main.buildTime=#{time.iso8601}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mkbrr version")

    (testpath/"hello.txt").write "Hello, World!"
    system bin/"mkbrr", "create", (testpath/"hello.txt"), "-o", (testpath/"hello.torrent")

    assert_path_exists testpath/"hello.torrent", "Failed to create torrent file"
  end
end
