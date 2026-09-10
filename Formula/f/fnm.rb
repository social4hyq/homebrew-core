class Fnm < Formula
  desc "Fast and simple Node.js version manager"
  homepage "https://github.com/Schniz/fnm"
  url "https://github.com/Schniz/fnm/archive/refs/tags/v1.39.0.tar.gz"
  sha256 "224081a677a02acd9f972885e824a98fa3843f5b778b28400ad5af97752f6127"
  license "GPL-3.0-only"
  head "https://github.com/Schniz/fnm.git", branch: "master"
  revision 2

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab3fc16aef5b1f281a60f0b51996c2b2cecd7a0907410c281570e036b40adb10"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  patch do
    file "Patches/fnm/0001-support-ohos.patch"
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"fnm", "completions", "--shell")
  end

  def caveats
    <<~EOS
      On OpenHarmony, the support tier of Node.js is currently marked
      as "Experimental", so the official distribution source
      nodejs.org/dist does not publish OpenHarmony binaries. You must
      specify a third-party distribution source to install OpenHarmony
      builds via fnm:

        export FNM_NODE_DIST_MIRROR="https://ohos-node.com/dist"

      This distribution source is maintained by a third-party
      developer. It is maintained neither by the official Node.js
      project nor by the official Harmonybrew project, and Harmonybrew
      makes no security guarantees about it. Please use it with caution.

      Add the following to your shell profile e.g. ~/.profile or ~/.zshrc:
        eval "$(fnm env)"
    EOS
  end

  test do
    system bin/"fnm", "--version"
  end
end
