class Dust < Formula
  desc "More intuitive version of du in rust"
  homepage "https://github.com/bootandy/dust"
  url "https://github.com/bootandy/dust/archive/refs/tags/v1.2.6.tar.gz"
  sha256 "9dd1ec7576d43574e6f48342cb96a5087338b4c308460a848f5895f72ddc3bc9"
  license "Apache-2.0"
  head "https://github.com/bootandy/dust.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "31133a93a709ddf198f7ebde46e8ac86f87e0b4eff953e9ed11b7405ca63e716"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    bash_completion.install "completions/dust.bash" => "dust"
    fish_completion.install "completions/dust.fish"
    zsh_completion.install "completions/_dust"

    man1.install "man-page/dust.1"
  end

  test do
    # failed with Linux CI run, but works with local run
    # https://github.com/Homebrew/homebrew-core/pull/121789#issuecomment-1407749790
    if OS.linux?
      system bin/"dust", "-n", "1"
    else
      assert_match(/\d+.+?\./, shell_output("#{bin}/dust -n 1"))
    end
  end
end
