class ImessageRuby < Formula
  desc "Command-line tool to send iMessage"
  homepage "https://github.com/linjunpop/imessage"
  url "https://github.com/linjunpop/imessage/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "09031e60548f34f05e07faeb0e26b002aeb655488d152dd811021fba8d850162"
  license "MIT"
  head "https://github.com/linjunpop/imessage.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c613ab55e71b9939d1e4187935296aadc429716fc9f57fcdcb077f03aebdc5e"
  end

  uses_from_macos "ruby"

  def install
    ENV["GEM_HOME"] = libexec
    ENV["GEM_PATH"] = libexec

    system "gem", "build", "imessage.gemspec", "-o", "imessage-#{version}.gem"
    system "gem", "install", "--local", "--verbose", "imessage-#{version}.gem", "--no-document"

    bin.install libexec/"bin/imessage"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    assert_match "imessage v#{version}", shell_output("#{bin}/imessage --version")
  end
end
