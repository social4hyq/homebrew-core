class Heksa < Formula
  desc "CLI hex dumper with colors"
  homepage "https://github.com/raspi/heksa"
  url "https://github.com/raspi/heksa.git",
      tag:      "v1.14.0",
      revision: "045ea335825556c856b2f4dee606ae91c61afe7d"
  license "Apache-2.0"
  head "https://github.com/raspi/heksa.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a05833c509e0abda4f0a8f3559459acc45ab02fc9cfabc6b2ebb12ef06e6a1d2"
  end

  depends_on "go" => :build

  def install
    system "make", "build"
    bin.install "bin/heksa"
  end

  test do
    require "pty"

    PTY.spawn("#{bin}/heksa -l 16 -f asc -o no #{test_fixtures("test.png")}") do |r, _w, pid|
      output = r.readline.gsub(/\e\[([;\d]+)?m/, "")
      assert_match(/^.PNG/, output)
    ensure
      Process.wait pid
    end
  end
end
