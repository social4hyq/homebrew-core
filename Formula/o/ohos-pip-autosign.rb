class OhosPipAutosign < Formula
  desc "Automated code signing for .so files in pip packages"
  homepage "https://atomgit.com/Harmonybrew/ohos-pip-autosign"
  url "https://atomgit.com/Harmonybrew/ohos-pip-autosign/releases/download/v1.0.0/ohos-pip-autosign-1.0.0.tar.gz"
  sha256 "c19145f6f52585746c0a75c2bdcd140c0ea732b904cce4e3a8d2a6265321381d"
  license "BSD-2-Clause"
  revision 3

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86ca990078141ca3d2d005696747a865e95ca704fa4f328e1c5a2924c36d58f5"
  end

  def install
    (bin/"ohos-pip-autosign").write <<~'EOS'
      #!/bin/sh
      echo 'Error:' >&2
      echo '  ohos-pip-autosign is no longer needed: the bundled pip' >&2
      echo '  of python@3.14, python@3.13 and python@3.12 now ships' >&2
      echo '  auto-signing. Run `brew upgrade` to upgrade your python' >&2
      echo '  and enjoy out-of-the-box auto-signing.' >&2
      exit 1
    EOS
    chmod 0755, bin/"ohos-pip-autosign"
  end

  test do
    output = shell_output("#{bin}/ohos-pip-autosign 2>&1", 1)
    assert_match(/no longer needed/, output)
    assert_match(/brew upgrade/, output)
  end
end
