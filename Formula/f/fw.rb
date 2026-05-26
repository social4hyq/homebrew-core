class Fw < Formula
  desc "Workspace productivity booster"
  homepage "https://github.com/brocode/fw"
  url "https://github.com/brocode/fw/archive/refs/tags/v2.21.0.tar.gz"
  sha256 "9a8b3b1f483118597e07de9561c0fac3412b896aa950243726ef553a705561ac"
  license "WTFPL"

  # This repository also contains version tags for other tools (e.g., `v4.4.0`
  # is an `fblog` tag), so we can't reliably determine which tags are for `fw`.
  # Upstream only creates GitHub releases from `fw` tags, so we have to check
  # releases instead.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0fdc4f949e2f7e1e0008d447ebc088594b15fd18359669a409dff0a3e79967b2"
  end

  depends_on "rust" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  resource "fw.1" do
    url "https://github.com/brocode/fw/releases/download/v2.21.0/fw.1"
    sha256 "2c27213d3c5dea906000ccb363ca70f167da0f67e74c243a890a935a102b3972"

    livecheck do
      formula :parent
    end
  end

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    system "cargo", "install", *std_cargo_args
    man1.install resource("fw.1")
  end

  test do
    assert_match "Synchronizing everything", shell_output("#{bin}/fw sync 2>&1", 1)
    assert_match "fw #{version}", shell_output("#{bin}/fw --version")
  end
end
