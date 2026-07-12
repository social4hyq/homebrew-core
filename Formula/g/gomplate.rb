class Gomplate < Formula
  desc "Command-line Golang template processor"
  homepage "https://gomplate.ca/"
  url "https://github.com/hairyhenderson/gomplate/archive/refs/tags/v5.2.0.tar.gz"
  sha256 "fb08872f54f776863a30adcd58dce0437529d0e6a468839d107803bbff1d0b23"
  license "MIT"
  head "https://github.com/hairyhenderson/gomplate.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84bc7ae3b6f3015418f37b462db4549747efc2ec2109b3f6e8808d6706da8924"
  end

  depends_on "go" => :build

  def install
    system "make", "build", "VERSION=#{version}"
    bin.install "bin/gomplate" => "gomplate"
    generate_completions_from_executable(bin/"gomplate", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/gomplate --version")
    assert_equal "gomplate version #{version}", output.chomp

    test_template = <<~EOS
      {{ range ("foo:bar:baz" | strings.SplitN ":" 2) }}{{.}}
      {{end}}
    EOS

    expected = <<~EOS
      foo
      bar:baz
    EOS

    assert_match expected, pipe_output(bin/"gomplate", test_template, 0)
  end
end
