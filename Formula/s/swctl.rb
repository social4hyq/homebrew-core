class Swctl < Formula
  desc "Apache SkyWalking CLI (Command-line Interface)"
  homepage "https://skywalking.apache.org/"
  license "Apache-2.0"
  head "https://github.com/apache/skywalking-cli.git", branch: "master"

  stable do
    url "https://github.com/apache/skywalking-cli/archive/refs/tags/0.14.0.tar.gz"
    sha256 "9b1861a659e563d2ba7284ac19f3ae72649f08ac7ff7064aee928a7df2cd2bff"

    # fish and zsh completion support patch, upstream pr ref, https://github.com/apache/skywalking-cli/pull/207
    patch do
      url "https://github.com/apache/skywalking-cli/commit/3f9cf0e74a97f16d8da48ccea49155fd45f2d160.patch?full_index=1"
      sha256 "dd17f332f86401ef4505ec7beb3f8863f13146718d8bdcf92d2cc2cdc712b0ec"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c92cf5414691dd7620394bdc254cbd7f33de0d81707f16c2463f0268b830dd0a"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/swctl"

    generate_completions_from_executable(bin/"swctl", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/swctl --version 2>&1")

    output = shell_output("#{bin}/swctl --display yaml service ls 2>&1", 1)
    assert_match "level=fatal msg=\"Post \\\"http://127.0.0.1:12800/graphql\\\"", output
  end
end
