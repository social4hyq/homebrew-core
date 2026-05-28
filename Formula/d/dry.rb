class Dry < Formula
  desc "Terminal application to manage Docker and Docker Swarm"
  homepage "https://moncho.github.io/dry/"
  url "https://github.com/moncho/dry/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "636d6b371bf329443849d19d574e8b493d77528d18167b52381df12755ba2ae7"
  license "MIT"
  head "https://github.com/moncho/dry.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4461b9f496f46eba12d5709272146378f418f935d0f730851a6bd268831c11c7"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/moncho/dry/version.VERSION=#{version}
      -X github.com/moncho/dry/version.GITCOMMIT=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dry --version")
    assert_match "A tool to interact with a Docker Daemon from the terminal", shell_output("#{bin}/dry --description")
  end
end
