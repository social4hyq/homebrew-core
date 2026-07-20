class Asimov < Formula
  desc "Automatically exclude development dependencies from Time Machine backups"
  homepage "https://github.com/stevegrunwell/asimov"
  url "https://github.com/stevegrunwell/asimov/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "70799e8b9428fd320322cd24b50336890ed58e887a15e13af074a733db6e823b"
  license "MIT"
  head "https://github.com/stevegrunwell/asimov.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b9a8a59b91362f46fabede62b7949b629609f92abf23479471bd292bae326882"
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
