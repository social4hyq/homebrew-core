class Asimov < Formula
  desc "Automatically exclude development dependencies from Time Machine backups"
  homepage "https://github.com/stevegrunwell/asimov"
  url "https://github.com/stevegrunwell/asimov/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "9fa0b1551cd3e741288701f589c1b1f42d16cb655f60283dce3a1bc7c5b9af67"
  license "MIT"
  head "https://github.com/stevegrunwell/asimov.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3711391bf3e8ee0648b619cf354405fb78cc698d32f262a8c6223d57ba7afa4a"
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
