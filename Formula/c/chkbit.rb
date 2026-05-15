class Chkbit < Formula
  desc "Check your files for data corruption"
  homepage "https://github.com/laktak/chkbit"
  url "https://github.com/laktak/chkbit/archive/refs/tags/v6.6.0.tar.gz"
  sha256 "69a5c709d78604ed9d21b5439b2fbae96e21f729d7d36f417d50348dc9fdcc81"
  license "MIT"
  head "https://github.com/laktak/chkbit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2dd88e876202170be7b6218688dfdd43e061886ed40634d5357b4bcaa530f5b2"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.appVersion=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/chkbit"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/chkbit version").chomp
    system bin/"chkbit", "init", "split", testpath
    assert_path_exists testpath/".chkbit"
  end
end
