class Ipatool < Formula
  desc "CLI tool for searching and downloading app packages from the iOS App Store"
  homepage "https://github.com/majd/ipatool"
  url "https://github.com/majd/ipatool/archive/refs/tags/v2.6.0.tar.gz"
  sha256 "6bffee11fabd26f930fe90d9841a9639151956ee3e8f8d0bb8e20bca05f9686c"
  license "MIT"
  head "https://github.com/majd/ipatool.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54ef1207c927d0c142d4a26058e805526ed96995d3bd9cfb31980f9c4df792aa"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1"
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/majd/ipatool/v2/cmd.version=#{version}")

    generate_completions_from_executable(bin/"ipatool", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ipatool --version")

    output = shell_output("#{bin}/ipatool auth info 2>&1", 1)
    assert_match "failed to get account", output
  end
end
