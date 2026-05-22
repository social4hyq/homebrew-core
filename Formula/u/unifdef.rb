class Unifdef < Formula
  desc "Selectively process conditional C preprocessor directives"
  homepage "https://dotat.at/prog/unifdef/"
  url "https://dotat.at/prog/unifdef/unifdef-2.12.tar.gz"
  sha256 "fba564a24db7b97ebe9329713ac970627b902e5e9e8b14e19e024eb6e278d10b"
  license all_of: [
    "BSD-2-Clause",
    "BSD-3-Clause", # only for `unifdef.1`
  ]
  head "https://github.com/fanf2/unifdef.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2e8d3f0d77958e8353f49edf2aa44891a9be72138c5899d9314fddf204a1703e"
  end

  keg_only :provided_by_macos

  def install
    system "make", "prefix=#{prefix}", "install"
  end

  test do
    pipe_output(bin/"unifdef", "echo ''")
  end
end
