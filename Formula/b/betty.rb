class Betty < Formula
  desc "English-like interface for the command-line"
  homepage "https://github.com/pickhardt/betty"
  url "https://github.com/pickhardt/betty/archive/refs/tags/v0.1.7.tar.gz"
  sha256 "ed71e88a659725e0c475888df044c9de3ab1474ff483f0a3bb432949035e62d3"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b554664a58715ea202ed2823d5f42a4f50225354e88b80a2285caa7e7cc82d5"
  end

  uses_from_macos "ruby"

  def install
    libexec.install "lib", "main.rb" => "betty"
    bin.write_exec_script libexec/"betty"
  end

  test do
    system bin/"betty", "what is your name"
    system bin/"betty", "version"
  end
end
