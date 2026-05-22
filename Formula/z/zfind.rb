class Zfind < Formula
  desc "Search for files (even inside tar/zip/7z/rar) using a SQL-WHERE filter"
  homepage "https://github.com/laktak/zfind"
  url "https://github.com/laktak/zfind/archive/refs/tags/v0.4.7.tar.gz"
  sha256 "49bc01da8446c8a97182f9794032d851614f0efc75b4f4810a114491a08d3bd4"
  license "MIT"
  head "https://github.com/laktak/zfind.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "328eaf66482c3cb7cfa3a5c51ba251f0866fe950eeb84261f3dafaa03643ff3f"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.appVersion=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/zfind"
  end

  test do
    output = shell_output("#{bin}/zfind --csv")
    assert_match "name,path,container,size,date,time,ext,ext2,type,archive", output

    assert_match version.to_s, shell_output("#{bin}/zfind --version")
  end
end
