class Committed < Formula
  desc "Nitpicking commit history since beabf39"
  homepage "https://github.com/crate-ci/committed"
  url "https://github.com/crate-ci/committed/archive/refs/tags/v1.1.11.tar.gz"
  sha256 "416aab32bf0cc2012259ee3ba264f3db0493164272694c6c4bef15e9258d4244"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/crate-ci/committed.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae74e37fb5d4819b9e1c32e97416a8d76588f36f74fef71edaf06991c39982c9"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/committed")
  end

  test do
    system "git", "init"
    system "git", "-c", "user.email=a@b.c", "-c", "user.name=t",
                  "commit", "--allow-empty", "-m", "bad message"
    output = shell_output("#{bin}/committed HEAD 2>&1", 1)
    assert_match "Subject", output
  end
end
