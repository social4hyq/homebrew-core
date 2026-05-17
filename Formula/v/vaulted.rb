class Vaulted < Formula
  desc "Allows the secure storage and execution of environments"
  homepage "https://github.com/miquella/vaulted"
  url "https://github.com/miquella/vaulted/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "ea5183f285930ffa4014d54d4ed80ac8f7aa9afd1114e5fce6e65f2e9ed1af0c"
  license "MIT"
  head "https://github.com/miquella/vaulted.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "97f6e889ca7e1235d854df41b467f55f3c93ffc5222042c917a64eff74404cfe"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    man1.install Dir["doc/man/vaulted*.1"]
  end

  test do
    (testpath/".local/share/vaulted").mkpath
    touch(".local/share/vaulted/test_vault")
    assert_equal "test_vault\n", shell_output("#{bin}/vaulted ls")
  end
end
