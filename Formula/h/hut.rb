class Hut < Formula
  desc "CLI tool for sr.ht"
  homepage "https://sr.ht/~xenrox/hut"
  url "https://git.sr.ht/~xenrox/hut/archive/v0.8.0.tar.gz"
  sha256 "f7994375673f253705ed7499f44b712b2d9fcec8a5a42f1d0408002552b7d0e7"
  license "AGPL-3.0-or-later"
  head "https://git.sr.ht/~xenrox/hut", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "040760674232554f5e49c7c56e4ab2ed15265ea5e1442acff2ddb61e0d3b062d"
  end

  depends_on "go" => :build
  depends_on "scdoc" => :build

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"config").write <<~EOS
      instance "sr.ht" {
          access-token "some_fake_access_token"
      }
    EOS
    assert_match "gqlclient: server failure: Invalid OAuth bearer token",
      shell_output("#{bin}/hut --config #{testpath}/config todo list 2>&1", 1)
  end
end
