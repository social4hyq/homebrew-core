class Cek < Formula
  desc "Explore the (overlay) filesystem and layers of OCI container images"
  homepage "https://github.com/bschaatsbergen/cek"
  url "https://github.com/bschaatsbergen/cek/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "df9c569279cccd4edd8d99fe334568ce141331dc4ab1aa77bffa3ae0d849bf94"
  license "MIT"
  head "https://github.com/bschaatsbergen/cek.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b7c58520f054b17173332c1b0de0015cde651d27d98bd3b6ad41544a94cb842f"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/bschaatsbergen/cek/version.Version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_includes shell_output("#{bin}/cek version"), "cek version #{version}"
    assert_match "localhost", shell_output("#{bin}/cek cat alpine:latest /etc/hostname")
  end
end
