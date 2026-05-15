class Kaf < Formula
  desc "Modern CLI for Apache Kafka"
  homepage "https://github.com/birdayz/kaf"
  url "https://github.com/birdayz/kaf/archive/refs/tags/v0.2.14.tar.gz"
  sha256 "83e78c19e5bce2d1922910809c19bacf489f6d16bbabefa6dcdd3e4b5c292b13"
  license "Apache-2.0"
  head "https://github.com/birdayz/kaf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "222feb3b607c92253d466513920f07fc45b06ab465fc74b7619fd579671025ba"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=Homebrew"
    system "go", "build", *std_go_args(ldflags:), "./cmd/kaf"

    generate_completions_from_executable(bin/"kaf", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kaf --version")

    system bin/"kaf", "config", "add-cluster", "local", "-b", "localhost:9092"
    system bin/"kaf", "config", "use-cluster", "local"
    assert_equal "local\n", shell_output("#{bin}/kaf config current-context")
  end
end
