class Dory < Formula
  desc "Development proxy for docker"
  homepage "https://github.com/freedomben/dory"
  url "https://github.com/FreedomBen/dory/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "8c385d898aed2de82f7d0ab5c776561ffe801dd4b222a07e25e5837953355b81"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fcf38ce0b1aeb20c9afcaa8abb4447256b6eac174ad98a82faedf31c2769e941"
  end

  depends_on "ruby"

  def install
    ENV["GEM_HOME"] = libexec
    system "gem", "build", "#{name}.gemspec"
    system "gem", "install", "#{name}-#{version}.gem"
    bin.install libexec/"bin/#{name}"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    shell_output(bin/"dory")

    system bin/"dory", "config-file"
    assert_path_exists testpath/".dory.yml", "Dory could not generate config file"

    version = shell_output("#{bin}/dory version")
    assert_match version.to_s, version, "Unexpected output of version"
  end
end
