class VaultCli < Formula
  desc "Subversion-like utility to work with Jackrabbit FileVault"
  homepage "https://jackrabbit.apache.org/filevault/index.html"
  url "https://search.maven.org/remotecontent?filepath=org/apache/jackrabbit/vault/vault-cli/4.2.0/vault-cli-4.2.0-bin.tar.gz"
  sha256 "a8f8ef02b6b50fd4227ad320490a55cfd78630ff2c902f4af7b0be38dda36f68"
  license "Apache-2.0"
  revision 1
  head "https://github.com/apache/jackrabbit-filevault.git", branch: "master"

  livecheck do
    url "https://search.maven.org/remotecontent?filepath=org/apache/jackrabbit/vault/vault-cli/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cf3cd4e4b32165070058714dac4ae0596681ddc4494cfc3c896f5254264aca68"
  end

  depends_on "openjdk"

  def install
    # Remove windows files
    rm(Dir["bin/*.bat"])

    libexec.install Dir["*"]
    bin.install libexec.glob("bin/*")
    bin.env_script_all_files(libexec/"bin", JAVA_HOME: Formula["openjdk"].opt_prefix)
  end

  test do
    # Bad test, but we're limited without a Jackrabbit repo to speak to...
    system bin/"vlt", "--version"
  end
end
