class SafeRm < Formula
  desc "Wraps rm to prevent dangerous deletion of files"
  homepage "https://launchpad.net/safe-rm"
  url "https://launchpad.net/safe-rm/trunk/1.1.0/+download/safe-rm-1.1.0.tar.gz"
  sha256 "a1c916894c5b70e02a6ec6c33abbb2c3b3827464cffd4baffd47ffb69a56a1e0"
  license "GPL-3.0-or-later"
  head "https://git.launchpad.net/safe-rm", using: :git, branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ad438d318b166199228ee28b3a4f4b9e2966f451305e42c14ca56863307fb84"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    foo = testpath/"foo"
    bar = testpath/"bar"
    (testpath/".config").mkdir
    (testpath/".config/safe-rm").write bar
    touch foo
    touch bar
    system bin/"safe-rm", foo
    refute_path_exists foo
    if OS.linux?
      shell_output("#{bin}/safe-rm #{bar} 2>&1", 1)
    else
      shell_output("#{bin}/safe-rm #{bar} 2>&1", 64)
    end

    assert_path_exists bar
  end
end
