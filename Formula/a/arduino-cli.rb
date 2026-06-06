class ArduinoCli < Formula
  desc "Arduino command-line interface"
  homepage "https://arduino.github.io/arduino-cli/latest/"
  url "https://github.com/arduino/arduino-cli/archive/refs/tags/v1.5.1.tar.gz"
  sha256 "262fbe874f62677d01eb15593144ca82bd6e7c2d0c00f82aa93949ab12924de6"
  license "GPL-3.0-only"
  head "https://github.com/arduino/arduino-cli.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46aebe446b8e0fd8a35511bfe4327a99bd8fd123cf6dc7baca73d71aa6101870"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/arduino/arduino-cli/internal/version.versionString=#{version}
      -X github.com/arduino/arduino-cli/internal/version.commit=#{tap.user}
      -X github.com/arduino/arduino-cli/internal/version.date=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"arduino-cli", shell_parameter_format: :cobra)
  end

  test do
    system bin/"arduino-cli", "sketch", "new", "test_sketch"
    assert_path_exists testpath/"test_sketch/test_sketch.ino"

    assert_match version.to_s, shell_output("#{bin}/arduino-cli version")
  end
end
