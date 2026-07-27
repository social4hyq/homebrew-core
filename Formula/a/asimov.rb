class Asimov < Formula
  desc "Automatically exclude development dependencies from Time Machine backups"
  homepage "https://github.com/stevegrunwell/asimov"
  url "https://github.com/stevegrunwell/asimov/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "9fb785e94af7dd93e240ce6659fd702bb99f4c3f5d2673754334455a867745cc"
  license "MIT"
  head "https://github.com/stevegrunwell/asimov.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ff3f9cd122962559b80193f4660ee8f0d22cac8a56e66922d96569c5622e847f"
  end

  def install
    bin.install buildpath/"asimov"
  end

  # Asimov will run in the background on a daily basis
  service do
    run opt_bin/"asimov"
    run_type :interval
    interval 86400 # 24 hours = 60 * 60 * 24
  end

  test do
    assert_match "No new directories to exclude", shell_output(bin/"asimov")
  end
end
