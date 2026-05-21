class WrenCli < Formula
  desc "Simple REPL and CLI tool for running Wren scripts"
  homepage "https://github.com/wren-lang/wren-cli"
  url "https://github.com/wren-lang/wren-cli/archive/refs/tags/0.4.0.tar.gz"
  sha256 "fafdc5d6615114d40de3956cd3a255e8737dadf8bd758b48bac00db61563cb4c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "40c144ec101cbf9d43bd483445fd24726697440a61eff301d27327f606138fb8"
  end

  # Backport fix for glibc >= 2.34
  patch do
    url "https://github.com/wren-lang/wren-cli/commit/18553636618a4d33f10af9b5ab92da6431784a8c.patch?full_index=1"
    sha256 "ee10f762901cecd897702aa5397868e880d64cfaded95ac76653ee1e01892eec"
  end

  def install
    if OS.mac?
      system "make", "-C", "projects/make.mac"
    else
      system "make", "-C", "projects/make"
    end
    bin.install "bin/wren_cli"
    pkgshare.install "example"
  end

  test do
    cp pkgshare/"example/hello.wren", testpath
    assert_equal "Hello, world!\n", shell_output("#{bin}/wren_cli hello.wren")
  end
end
