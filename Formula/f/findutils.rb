class Findutils < Formula
  desc "Collection of GNU find, xargs, and locate"
  homepage "https://www.gnu.org/software/findutils/"
  url "https://ftpmirror.gnu.org/gnu/findutils/findutils-4.11.0.tar.xz"
  mirror "https://ftp.gnu.org/gnu/findutils/findutils-4.11.0.tar.xz"
  sha256 "bfd19cb06cc71f3352d567e90284d8cdac02ac89774bbeadf0b533b0c11432fd"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e60897ffc6403b58b411d4b3ae55e121e17502648c9c8787278455d1ad8a5342"
  end

  patch do
    file "Patches/findutils/0001-port-gnulib-to-ohos.patch"
  end

  def install
    args = %W[
      --disable-nls
      --localstatedir=#{var}/locate
      --with-packager=Homebrew
      --with-packager-bug-reports=#{tap.issues_url}
    ]
    args << "--program-prefix=g" if OS.mac?

    system "./configure", *args, *std_configure_args
    system "make", "install"

    if OS.mac?
      [[prefix, bin], [share, man/"*"]].each do |base, path|
        Dir[path/"g*"].each do |p|
          f = Pathname.new(p)
          gnupath = "gnu" + f.relative_path_from(base).dirname
          (libexec/gnupath).install_symlink f => f.basename.sub(/^g/, "")
        end
      end
    end

    (libexec/"gnubin").install_symlink "../gnuman" => "man"
    (var/"locate").mkpath
  end

  def caveats
    on_macos do
      <<~EOS
        All commands have been installed with the prefix "g".
        If you need to use these commands with their normal names, you
        can add a "gnubin" directory to your PATH from your bashrc like:
          PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    touch "HOMEBREW"
    if OS.mac?
      assert_match "HOMEBREW", shell_output("#{bin}/gfind .")
      assert_match "HOMEBREW", shell_output("#{opt_libexec}/gnubin/find .")
    else
      assert_match "HOMEBREW", shell_output("#{bin}/find .")
    end
  end
end
