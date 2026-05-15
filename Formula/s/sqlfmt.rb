class Sqlfmt < Formula
  desc "SQL formatter with width-aware output"
  homepage "https://sqlfum.pt/"
  url "https://github.com/maddyblue/sqlfmt/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "0776e9505048fd88220c0ee9b481ca258b6abe7e7bb27204a4873f11e1d7c95b"
  license "Apache-2.0"
  head "https://github.com/maddyblue/sqlfmt.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "13113cb7970f673760bbc3a8c274cd515e80680f6b0d10ef65857ef52f023af1"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:), "./backend"
  end

  test do
    test_sql = "\"SELECT count(ID) AS count, foo FROM brewtest GROUP BY foo;\""
    assert_equal <<~EOS, shell_output("#{bin}/sqlfmt --print-width 40 --stmt #{test_sql}")
      SELECT
      \tcount(id) AS count, foo
      FROM
      \tbrewtest
      GROUP BY
      \tfoo;
    EOS

    assert_match version.to_s, shell_output("#{bin}/sqlfmt --version")
  end
end
