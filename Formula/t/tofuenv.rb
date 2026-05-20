class Tofuenv < Formula
  desc "OpenTofu version manager inspired by tfenv"
  homepage "https://tofuutils.github.io/tofuenv/"
  url "https://github.com/tofuutils/tofuenv/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "047c6a01a0d4c7ded2cf126ae1e891bb3479b2544ec2d2f0d3951de2d08f6c7d"
  license "MIT"
  head "https://github.com/tofuutils/tofuenv.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71420596dd741ecfbcc75f3022120baef7e660b69161224487df0473e35c518c"
  end

  uses_from_macos "jq", since: :sequoia
  uses_from_macos "unzip"

  on_macos do
    depends_on "grep"
  end

  conflicts_with "opentofu", "tenv", because: "both install tofu binary"

  def install
    prefix.install %w[bin lib libexec share]
  end

  test do
    tf_version = shell_output("#{bin}/tofuenv list-remote").lines.first.chomp
    with_env(TOFUENV_TOFU_VERSION: tf_version, TF_AUTO_INSTALL: "false") do
      assert_equal tf_version, shell_output("#{bin}/tofuenv version-name").strip
    end
  end
end
