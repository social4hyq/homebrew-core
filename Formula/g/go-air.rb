class GoAir < Formula
  desc "Live reload for Go apps"
  homepage "https://github.com/air-verse/air"
  url "https://github.com/air-verse/air/archive/refs/tags/v1.65.3.tar.gz"
  sha256 "35fde02b7cdc39cf3a53e97187e894c443dcdeb1475bc654250cbb5c22428a80"
  license "GPL-3.0-or-later"
  head "https://github.com/air-verse/air.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a0d180daa3d115d9e3ccea5d5c1268a7c010cada76a11ae50f376d5c69ecbb3e"
  end

  depends_on "go"

  conflicts_with "air", because: "both install binaries with the same name"

  def install
    ldflags = %W[
      -s -w
      -X main.BuildTimestamp=#{time.iso8601}
      -X main.airVersion=v#{version}
      -X main.goVersion=#{Formula["go"].version}
    ]
    system "go", "build", *std_go_args(ldflags: ldflags.join(" "), output: bin/"air")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/air -v 2>&1")
    (testpath/"air-test").mkpath
    cd testpath/"air-test" do
      system "go", "mod", "init", "air-test"
      system bin/"air", "init"
    end
    assert_path_exists testpath/"air-test/.air.toml"
  end
end
