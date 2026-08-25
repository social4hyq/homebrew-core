class BashPreexec < Formula
  desc "Preexec and precmd functions for Bash (like Zsh)"
  homepage "https://github.com/rcaloras/bash-preexec"
  url "https://github.com/rcaloras/bash-preexec/archive/refs/tags/0.7.0.tar.gz"
  sha256 "f3d5698bde8533e9622b2ee2dcb0dd12e772d85018f4770a8899887ef6cd36a0"
  license "MIT"
  head "https://github.com/rcaloras/bash-preexec.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7d6602752445ceec50bab87c55c874dcd0e1b5cf2e6fd704bbe14bc4b720ff3a"
  end

  def install
    (prefix/"etc/profile.d").install "bash-preexec.sh"
  end

  def caveats
    <<~EOS
      Add the following line to your bash profile (e.g. ~/.bashrc, ~/.profile, or ~/.bash_profile)
        [ -f #{etc}/profile.d/bash-preexec.sh ] && . #{etc}/profile.d/bash-preexec.sh
    EOS
  end

  test do
    # Just testing that the file is installed
    assert_path_exists testpath/"#{prefix}/etc/profile.d/bash-preexec.sh"
  end
end
