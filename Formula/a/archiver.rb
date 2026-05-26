class Archiver < Formula
  desc "Cross-platform, multi-format archive utility"
  homepage "https://github.com/mholt/archiver"
  url "https://github.com/mholt/archiver/archive/refs/tags/v3.5.1.tar.gz"
  sha256 "b69a76f837b6cc1c34c72ace16670360577b123ccc17872a95af07178e69fbe7"
  license "MIT"
  head "https://github.com/mholt/archiver.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "28180a74e985ef919a09646fe6178c10e74ad4f5db0154dc096a8433342f94df"
  end

  deprecate! date: "2025-04-27", because: :repo_archived
  disable! date: "2026-04-27", because: :repo_archived

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"arc"), "./cmd/arc"
  end

  test do
    output = shell_output("#{bin}/arc --help 2>&1")
    assert_match "Usage: arc {archive|unarchive", output

    (testpath/"test1").write "Hello!"
    (testpath/"test2").write "Bonjour!"
    (testpath/"test3").write "Moien!"

    system bin/"arc", "archive", "test.zip",
           "test1", "test2", "test3"

    assert_path_exists testpath/"test.zip"
    assert_match "Zip archive data",
                 shell_output("file -b #{testpath}/test.zip")

    output = shell_output("#{bin}/arc ls test.zip")
    names = output.lines.map do |line|
      columns = line.split(/\s+/)
      File.basename(columns.last)
    end
    assert_match "test1 test2 test3", names.join(" ")
  end
end
