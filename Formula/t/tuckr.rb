class Tuckr < Formula
  desc "Super powered replacement for GNU Stow"
  homepage "https://raphgl.github.io/Tuckr/"
  url "https://github.com/RaphGL/Tuckr/archive/refs/tags/0.13.1.tar.gz"
  sha256 "4b3bdc51e5de5961d89021f28e5aa1ae976fe37330ffafaa5042ed7d6ee2c7c7"
  license "GPL-3.0-or-later"
  head "https://github.com/RaphGL/Tuckr.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de93ce392b227a49bbfcf2338385a72c95ccf20ca6adc0e7b3a3b8451801cdc8"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = shell_output("#{bin}/tuckr status 2>&1", 2)
    assert_match "Couldn't find dotfiles directory", output
    assert_match "run `tuckr init`.", output
    assert_match version.to_s, shell_output("#{bin}/tuckr --version")
  end
end
