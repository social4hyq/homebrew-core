class Immortal < Formula
  desc "OS agnostic (*nix) cross-platform supervisor"
  homepage "https://immortal.run/"
  url "https://github.com/immortal/immortal/archive/refs/tags/v0.24.7.tar.gz"
  sha256 "f4e646bda8ed8124271f002ceefea4949fcb8d70e2ec55856641b4be8cf69c51"
  license "BSD-3-Clause"
  head "https://github.com/immortal/immortal.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "beeecdd35b81d0e36a328147324a8fbf26f46740f4dd09751caf8b84d454f372"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    %w[immortal immortalctl immortaldir].each do |file|
      system "go", "build", *std_go_args(ldflags:, output: bin/file), "cmd/#{file}/main.go"
    end
    man8.install Dir["man/*.8"]
  end

  test do
    system bin/"immortal", "-v"
    system bin/"immortalctl", "-v"
    system bin/"immortaldir", "-v"
  end
end
