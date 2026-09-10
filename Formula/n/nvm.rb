class Nvm < Formula
  desc "Manage multiple Node.js versions"
  homepage "https://github.com/nvm-sh/nvm"
  url "https://github.com/nvm-sh/nvm/archive/refs/tags/v0.40.7.tar.gz"
  sha256 "d2fb84dba9914b02cd69b97df35dfca8695b8f22df6128667034d85b69b52d57"
  license "MIT"
  head "https://github.com/nvm-sh/nvm.git", branch: "master"
  revision 3

  # Hardcode the platform identifier to ensure this nvm can run
  # on any minimalist system environment (e.g., DockerHarmony).
  patch do
    file "Patches/nvm/0001-hardcode-platform.patch"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4b22bc1ecfda1ca10deadbfd75fb56610b3ae2ae287f096022e0aede91a3b481"
  end

  def install
    (prefix/"nvm.sh").write <<~SH
      # $NVM_DIR should be "$HOME/.nvm" by default to avoid user-installed nodes destroyed every update
      [ -z "$NVM_DIR" ] && export NVM_DIR="$HOME/.nvm"
      \\. #{libexec}/nvm.sh
      # "nvm exec" and certain 3rd party scripts expect "nvm.sh" and "nvm-exec" to exist under $NVM_DIR
      [ -e "$NVM_DIR" ] || mkdir -p "$NVM_DIR"
      [ -e "$NVM_DIR/nvm.sh" ] || ln -s #{opt_libexec}/nvm.sh "$NVM_DIR/nvm.sh"
      [ -e "$NVM_DIR/nvm-exec" ] || ln -s #{opt_libexec}/nvm-exec "$NVM_DIR/nvm-exec"
    SH
    libexec.install "nvm.sh", "nvm-exec"
    prefix.install_symlink libexec/"nvm-exec"
    bash_completion.install "bash_completion" => "nvm"
  end

  def caveats
    <<~EOS
      Please note that upstream has asked us to make explicit managing
      nvm via Homebrew is unsupported by them and you should check any
      problems against the standard nvm install method prior to reporting.

      On OpenHarmony, the support tier of Node.js is currently marked
      as "Experimental", so the official distribution source
      nodejs.org/dist does not publish OpenHarmony binaries. You must
      specify a third-party distribution source to install OpenHarmony
      builds via nvm:

        export NVM_NODEJS_ORG_MIRROR="https://ohos-node.com/dist"

      This distribution source is maintained by a third-party
      developer. It is maintained neither by the official Node.js
      project nor by the official Harmonybrew project, and Harmonybrew
      makes no security guarantees about it. Please use it with caution.

      You should create NVM's working directory if it doesn't exist:
        mkdir ~/.nvm

      Add the following to your shell profile e.g. ~/.profile or ~/.zshrc:
        export NVM_DIR="$HOME/.nvm"
        [ -s "#{opt_prefix}/nvm.sh" ] && \\. "#{opt_prefix}/nvm.sh"  # This loads nvm
        [ -s "#{opt_prefix}/etc/bash_completion.d/nvm" ] && \\. "#{opt_prefix}/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

      You can set $NVM_DIR to any location, but leaving it unchanged from
      #{prefix} will destroy any nvm-installed Node installations
      upon upgrade/reinstall.

      Type `nvm help` for further information.
    EOS
  end

  test do
    output = pipe_output("NODE_VERSION=homebrewtest #{prefix}/nvm-exec 2>&1")
    refute_match(/No such file or directory/, output)
    refute_match(/nvm: command not found/, output)
    assert_match "N/A: version \"homebrewtest\" is not yet installed", output
  end
end
