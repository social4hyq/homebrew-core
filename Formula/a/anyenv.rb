class Anyenv < Formula
  desc "All in one for **env"
  homepage "https://anyenv.github.io/"
  url "https://github.com/anyenv/anyenv/archive/refs/tags/v1.1.5.tar.gz"
  sha256 "ed086fb8f5ee6bd8136364c94a9a76a24c65e0a950bb015e1b83389879a56ba8"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6d8a772318f028fc187e349a848fd78041dc7876e040f843980be5272ac01492"
  end

  def install
    inreplace "libexec/anyenv", "/usr/local", HOMEBREW_PREFIX
    prefix.install %w[bin completions libexec]
  end

  test do
    anyenv_root = testpath/"anyenv"
    profile = testpath/".profile"
    profile.write <<~SHELL
      export ANYENV_ROOT=#{anyenv_root}
      export ANYENV_DEFINITION_ROOT=#{testpath}/anyenv-install
      eval "$(#{bin}/anyenv init -)"
    SHELL

    anyenv_install = ". #{profile} && #{bin}/anyenv install"
    assert_match "Completed!", shell_output("#{anyenv_install} --force-init")
    assert_match(/^\s*rbenv$/, shell_output("#{anyenv_install} --list"))
    assert_match "succeeded!", shell_output("#{anyenv_install} rbenv")

    anyenv_rbenv_path = "#{anyenv_root}/envs/rbenv/bin/rbenv"
    assert_equal anyenv_rbenv_path, shell_output(". #{profile} && which rbenv").chomp
    assert_match(/^\d+\.\d+\.\d+$/, shell_output(". #{profile} && rbenv install --list"))
  end
end
