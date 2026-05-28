class PipeRename < Formula
  desc "Rename your files using your favorite text editor"
  homepage "https://github.com/marcusbuffett/pipe-rename"
  url "https://github.com/marcusbuffett/pipe-rename/archive/refs/tags/1.6.7.tar.gz"
  sha256 "011d8ec263af85a9c2037098b1d5bf0ee271a3c1731e6de597bf02ccc81b55a2"
  license "MIT"
  head "https://github.com/marcusbuffett/pipe-rename.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0b8f3e850127f3098aefd8933d8026adff53cb3145094d65329c74fda0fee3d4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    touch "test.log"
    (testpath/"rename.sh").write <<~SHELL
      #!/bin/sh
      echo "$(cat "$1").txt" > "$1"
    SHELL

    chmod "+x", testpath/"rename.sh"
    ENV["EDITOR"] = testpath/"rename.sh"
    system bin/"renamer", "-y", "test.log"
    assert_path_exists testpath/"test.log.txt"
  end
end
