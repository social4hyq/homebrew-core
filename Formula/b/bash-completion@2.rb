class BashCompletionAT2 < Formula
  desc "Programmable completion for Bash 4.2+"
  homepage "https://github.com/scop/bash-completion"
  url "https://github.com/scop/bash-completion/releases/download/2.18.0/bash-completion-2.18.0.tar.xz"
  sha256 "88bcf85124f77f74f2f2f8bcd16ac4382d807a827ede742a64940c7116aea33f"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ea503a444dfc626e7200d0dd33d2161ad9299bc274aa10d098924b287d79cef3"
  end

  head do
    url "https://github.com/scop/bash-completion.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  on_macos do
    depends_on "bash"
  end

  conflicts_with "bash-completion", because: "each are different versions of the same formula"

  def install
    inreplace "bash_completion" do |s|
      # `/usr/bin/readlink -f` exists since macOS 12.3. Older systems
      # (including earlier Monterey releases) do not support this option.
      s.gsub! "readlink -f", "readlink" if OS.mac? && MacOS.version <= :monterey
      # Automatically read Homebrew's existing v1 completions
      s.gsub! "(/etc/bash_completion.d)", "(#{etc}/bash_completion.d)"
    end

    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *std_configure_args
    ENV.deparallelize
    system "make", "install"
  end

  def caveats
    <<~EOS
      Add the following line to your ~/.bash_profile:
        [[ -r "#{etc}/profile.d/bash_completion.sh" ]] && . "#{etc}/profile.d/bash_completion.sh"
    EOS
  end

  test do
    system "test", "-f", "#{share}/bash-completion/bash_completion"
  end
end
