class GitFixup < Formula
  desc "Alias for git commit --fixup <ref>"
  homepage "https://github.com/keis/git-fixup"
  url "https://github.com/keis/git-fixup/archive/refs/tags/v1.6.1.tar.gz"
  sha256 "414d207687059094df9603c79d5e52343704e077b72777f25eda4d6ce291046e"
  license "ISC"
  head "https://github.com/keis/git-fixup.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7a6ac292359678ab7dcc20af15240c55b2bc36f1060826ee8f0a250fb88e56cb"
  end

  def install
    system "make", "PREFIX=#{prefix}", "install"
    zsh_completion.install "completion.zsh" => "_git-fixup"
    fish_completion.install "completion.fish" => "git-fixup.fish"
  end

  test do
    (testpath/".gitconfig").write <<~EOS
      [user]
        name = Real Person
        email = notacat@hotmail.cat
    EOS
    system "git", "init"
    (testpath/"test").write "foo"
    system "git", "add", "test"
    system "git", "commit", "--message", "Initial commit"

    (testpath/"test").delete
    (testpath/"test").write "bar"
    system "git", "add", "test"
    system "git", "fixup"
  end
end
