class OhosPipAutosign < Formula
  desc "Automated code signing for .so files in pip packages"
  homepage "https://atomgit.com/Harmonybrew/ohos-pip-autosign"
  url "https://atomgit.com/Harmonybrew/ohos-pip-autosign/releases/download/v1.0.0/ohos-pip-autosign-1.0.0.tar.gz"
  sha256 "c19145f6f52585746c0a75c2bdcd140c0ea732b904cce4e3a8d2a6265321381d"
  license "BSD-2-Clause"

  depends_on "ohos-sdk"

  def install
    bin.install "bin/ohos-pip-autosign"
    libexec.install "libexec/_ohos_pip_autosign_hook.py"
  end

  test do
    system bin/"ohos-pip-autosign", "--help"
  end
end
