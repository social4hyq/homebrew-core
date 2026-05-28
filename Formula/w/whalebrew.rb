class Whalebrew < Formula
  desc "Homebrew, but with Docker images"
  homepage "https://github.com/whalebrew/whalebrew"
  url "https://github.com/whalebrew/whalebrew/archive/refs/tags/0.5.0.tar.gz"
  sha256 "2abea4171dbdca429b6476cffdfe7c94ce27028dc5d96e0f3a9a4fdeab77c4fb"
  license "Apache-2.0"
  head "https://github.com/whalebrew/whalebrew.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "017a70da5495045ec20d8e2ef9bfc99af1acd5d1ebd06ae34692a4d70621bfbb"
  end

  depends_on "go" => :build
  depends_on "docker" => :test

  # Run "go mod tidy": https://github.com/whalebrew/whalebrew/pull/299
  patch do
    url "https://github.com/whalebrew/whalebrew/commit/f64b9db9a5f1c91571a622a58eb93233f8c59642.patch?full_index=1"
    sha256 "62d5cb208d60ed123a5be234a1c3d48aeead703a83eb262408a101aec66bd0d6"
  end

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    ldflags = %W[
      -s -w
      -X github.com/whalebrew/whalebrew/version.Version=#{version}+homebrew
    ]
    system "go", "build", *std_go_args(ldflags:)
    generate_completions_from_executable(bin/"whalebrew", shell_parameter_format: :cobra)
  end

  test do
    assert_match "Whalebrew #{version}+homebrew", shell_output("#{bin}/whalebrew version")
    assert_match "whalebrew/whalesay", shell_output("#{bin}/whalebrew search whalesay")

    output = shell_output("#{bin}/whalebrew install whalebrew/whalesay -y 2>&1", 255)
    assert_match(/failed to connect to the docker API|permission denied/, output)
  end
end
