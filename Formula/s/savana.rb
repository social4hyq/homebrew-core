class Savana < Formula
  desc "Transactional workspaces for SVN"
  homepage "https://github.com/codehaus/savana"
  url "https://search.maven.org/remotecontent?filepath=org/codehaus/savana/1.2/savana-1.2-install.tar.gz"
  sha256 "608242a0399be44f41ff324d40e82104b3c62908bc35177f433dcfc5b0c9bf55"
  license "LGPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "07a5d9cae59dab6b80c5374e7e900f44f2d8b46acd39c29abe160254bd3ed034"
  end

  depends_on "openjdk"

  def install
    # Remove Windows files
    rm_r(Dir["bin/*.{bat,cmd}"])

    prefix.install %w[COPYING COPYING.LESSER licenses svn-hooks]

    # lib/* and logging.properties are loaded relative to bin
    prefix.install "bin"
    libexec.install %w[lib logging.properties]
    bin.env_script_all_files libexec/"bin", JAVA_HOME: Formula["openjdk"].opt_prefix

    bash_completion.install "etc/bash_completion" => "sav"
  end

  test do
    system bin/"sav", "help"
  end
end
