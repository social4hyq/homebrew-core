class Zsh < Formula
  desc "UNIX shell (command interpreter)"
  homepage "https://www.zsh.org/"
  license all_of: [
    "MIT-Modern-Variant",
    "GPL-2.0-only", # Completion/Linux/Command/_qdbus, Completion/openSUSE/Command/{_osc,_zypper}
    "GPL-2.0-or-later", # Completion/Unix/Command/_darcs
    "ISC", # Src/openssh_bsd_setres_id.c
  ]

  revision 2

  stable do
    url "https://downloads.sourceforge.net/project/zsh/zsh/5.9.2/zsh-5.9.2.tar.xz"
    mirror "https://www.zsh.org/pub/zsh-5.9.2.tar.xz"
    sha256 "36fa734374b44783582cec09bcd67822e2f992c779ec1624ab5596df078d2f81"

    resource "htmldoc" do
      url "https://downloads.sourceforge.net/project/zsh/zsh-doc/5.9.2/zsh-5.9.2-doc.tar.xz"
      mirror "https://www.zsh.org/pub/zsh-5.9.2-doc.tar.xz"
      sha256 "020ee644be1749507b282e619cdcd95c56ff36144e79b7a3c245458aacd9458f"

      livecheck do
        formula :parent
      end
    end
  end

  livecheck do
    url "https://sourceforge.net/projects/zsh/rss?path=/zsh"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zsh-v5.9.2-r5"
    rebuild 2
  end

  head do
    url "https://git.code.sf.net/p/zsh/code.git", branch: "master"
    depends_on "autoconf" => :build
  end

  depends_on "ncurses"
  depends_on "pcre2"

  on_system :linux, macos: :ventura_or_newer do
    depends_on "texinfo" => :build
  end

  def install
    # Fix compile with newer Clang. Remove in the next release
    # Ref: https://sourceforge.net/p/zsh/code/ci/ab4d62eb975a4c4c51dd35822665050e2ddc6918/
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    # OHOS 适配：默认（dynamic）模式下 zsh 模块用 dlopen 加载，需要从主二进制
    # 解析 backwardmetafiedchar / thingytab 等符号。但 OHOS 的 musl 动态链接器
    # 在 dlopen 时不解析主二进制的 .dynsym（即使 -rdynamic/--export-dynamic
    # 导出了符号），导致模块加载报 "symbol not found"。系统 /usr/bin/zsh 的
    # 模块是静态内建的，能正常使用。--disable-dynamic 让所有模块静态链接进
    # 主二进制，与系统 zsh 一致，绕开 OHOS dlopen 限制。

    system "Util/preconfig" if build.head?

    system "./configure", "--prefix=#{prefix}",
           "--disable-dynamic",
           "--enable-fndir=#{pkgshare}/functions",
           "--enable-scriptdir=#{pkgshare}/scripts",
           "--enable-site-fndir=#{HOMEBREW_PREFIX}/share/zsh/site-functions",
           "--enable-site-scriptdir=#{HOMEBREW_PREFIX}/share/zsh/site-scripts",
           "--enable-runhelpdir=#{pkgshare}/help",
           "--enable-cap",
           "--enable-maildir-support",
           "--enable-multibyte",
           "--enable-pcre",
           "--enable-zsh-secure-free",
           "--enable-unicode9",
           "--enable-etcdir=/etc",
           "--with-tcsetpgrp",
           "DL_EXT=bundle"

    # Do not version installation directories.
    inreplace ["Makefile", "Src/Makefile"],
              "$(libdir)/$(tzsh)/$(VERSION)", "$(libdir)"

    if build.head?
      # disable target install.man, because the required yodl comes neither with macOS nor Homebrew
      # also disable install.runhelp and install.info because they would also fail or have no effect
      system "make", "install.bin", "install.modules", "install.fns"
    else
      system "make", "install"
      # OHOS: skip install.info — MiscXS.c is pinned to perl 5.42 API but
      # the CI image ships perl 5.44, causing a version mismatch build error.
      # The info pages are non-essential (htmldoc resource covers docs).

      resource("htmldoc").stage do
        (pkgshare/"htmldoc").install Dir["Doc/*.html"]
      end
    end
  end

  test do
    assert_equal "homebrew", shell_output("#{bin}/zsh -c 'echo homebrew'").chomp
    system bin/"zsh", "-c", "printf -v hello -- '%s'"
    system bin/"zsh", "-c", "zmodload zsh/pcre"
    system bin/"zsh", "-c", "zmodload zsh/complete"
    system bin/"zsh", "-c", "zmodload zsh/zleparameter"
  end
end
