class Serveit < Formula
  desc "Synchronous server and rebuilder of static content"
  homepage "https://github.com/garybernhardt/serveit"
  url "https://github.com/garybernhardt/serveit/archive/refs/tags/v0.0.3.tar.gz"
  sha256 "5bbefdca878aab4a8c8a0c874c02a0a033cf4321121c9e006cb333d9bd7b6d52"
  license "MIT"
  revision 1
  head "https://github.com/garybernhardt/serveit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac6cd73e28d327101b7f2ad63c2dd6ee212bd2dd33f12fcf2be5b69f7d91b074"
  end

  depends_on "ruby"

  # webrick is needed for ruby 3.0+ (as it is not part of the default gems)
  # upstream report, https://github.com/garybernhardt/serveit/issues/13
  resource "webrick" do
    url "https://rubygems.org/downloads/webrick-1.8.1.gem"
    sha256 "19411ec6912911fd3df13559110127ea2badd0c035f7762873f58afc803e158f"
  end

  def install
    ENV["GEM_HOME"] = libexec
    resources.each do |r|
      system "gem", "install", r.cached_download, "--ignore-dependencies",
                    "--no-document", "--install-dir", libexec
    end
    bin.install "serveit"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    port = free_port
    pid = spawn bin/"serveit", "-p", port.to_s
    sleep 2
    assert_match(/Listing for/, shell_output("curl localhost:#{port}"))
  ensure
    Process.kill("SIGINT", pid)
    Process.wait(pid)
  end
end
