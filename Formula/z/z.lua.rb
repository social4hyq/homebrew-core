class ZLua < Formula
  desc "New cd command that helps you navigate faster by learning your habits"
  homepage "https://github.com/skywind3000/z.lua"
  url "https://github.com/skywind3000/z.lua/archive/refs/tags/v1.8.25.tar.gz"
  sha256 "625197abaddb7c89367133260f8e39851377f21221a544b2a5f213af51cfa822"
  license "MIT"
  head "https://github.com/skywind3000/z.lua.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80a0720b52df3a787634ed84598c71875a8eca4aec5f2a8c0c67b7bb4792bd32"
  end

  depends_on "lua"

  def install
    # Avoid using Cellar paths at runtime. This breaks when z.lua is upgraded.
    inreplace "z.lua.plugin.zsh", /^(ZLUA_SCRIPT=").*"$/, "\\1#{opt_pkgshare}/z.lua\""
    pkgshare.install "z.lua", "z.lua.plugin.zsh", "init.fish"
    doc.install "README.md", "LICENSE"
  end

  def caveats
    <<~EOS
      Zsh users: add line below to your ~/.zshrc
        eval "$(lua $(brew --prefix z.lua)/share/z.lua/z.lua --init zsh)"

      Bash users: add line below to your ~/.bashrc
        eval "$(lua $(brew --prefix z.lua)/share/z.lua/z.lua --init bash)"
    EOS
  end

  test do
    system "lua", "#{opt_pkgshare}/z.lua", "."
  end
end
