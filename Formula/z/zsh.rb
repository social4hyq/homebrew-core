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

  depends_on "ohos-bst-light" => :build
  depends_on "ncurses"
  depends_on "pcre2"

  on_system :linux, macos: :ventura_or_newer do
    depends_on "texinfo" => :build
  end

  def install
    # Fix compile with newer Clang. Remove in the next release
    # Ref: https://sourceforge.net/p/zsh/code/ci/ab4d62eb975a4c4c51dd35822665050e2ddc6918/
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    # OHOS 适配：zsh 模块（.bundle）在 dlopen 时需要从主二进制解析
    # backwardmetafiedchar / thingytab 等内部符号。-rdynamic 把全局符号
    # 导出到 .dynsym，否则模块加载报 "symbol not found"。
    # 系统 /usr/bin/zsh 天然带 DF_SYMBOLIC（等效），brew 版需显式加。
    # zsh configure 有 -rdynamic 检测（zsh_cv_rdynamic_available），但在
    # OHOS 容器里该检测可能失败。直接预设 EXTRA_LDFLAGS 绕过检测。
    # 同时覆盖 EXELDFLAGS：默认值含 -s（strip all），会移除 .dynsym 导出
    # 符号，使 -rdynamic 失效。改为只用 -rdynamic，不 strip。
    # OHOS 适配：zsh 模块（.bundle）在 dlopen 时需要从主二进制解析
    # backwardmetafiedchar / thingytab 等内部符号。OHOS LLD 忽略 -rdynamic
    # 和 --export-dynamic，必须用 --dynamic-list 显式导出全部全局符号。
    dynlist = buildpath/"zsh_dynlist"
    dynlist.write "{ *; };\n"
    ENV["EXTRA_LDFLAGS"] = "-Wl,--dynamic-list=#{dynlist}"
    ENV["EXELDFLAGS"] = "-Wl,--dynamic-list=#{dynlist}"

    system "Util/preconfig" if build.head?

    system "./configure", "--prefix=#{prefix}",
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

    # Debug: verify -rdynamic exported the symbol to .dynsym before signing
    dynsym = Utils.safe_popen_read("llvm-readelf", "--dyn-syms", (bin/"zsh").to_s)
    unless dynsym.include?("backwardmetafiedchar")
      odie "-rdynamic failed: backwardmetafiedchar not in .dynsym of #{bin}/zsh. " \
           "Link command had -rdynamic but symbol is missing from dynamic symbol table."
    end

    # OHOS 签名适配：自动签名管线的 llvm-strip（默认 --strip-all）会移除
    # .dynsym 中 -rdynamic 导出的内部符号（backwardmetafiedchar 等），
    # 导致 dlopen 模块加载失败。自己用 ohos-bst-light self-sign 签名
    # （不做 strip），配合 build.sh UNSET_SIGN_FORMULAS 跳过自动签名。
    odie_if_sign = ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
    if odie_if_sign
      odie "zsh must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(see build.sh UNSET_SIGN_FORMULAS): the auto-sign llvm-strip pass " \
           "removes -rdynamic-exported .dynsym symbols that dlopen modules need"
    end

    prefix.find do |path|
      next if path.directory? || path.symlink? || path.size < 18

      header = path.read(18).dup.b
      next if header[0..3] != "\x7fELF".b

      # Skip files that already have a .codesign section (e.g. hardlinks
      # like bin/zsh and bin/zsh-5.9.2 — signing one covers both).
      sections = Utils.safe_popen_read("llvm-readelf", "-S", path.to_s).to_s
      next if sections.include?(".codesign")

      system formula_opt_bin("ohos-bst-light")/"self-sign", path.to_s
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
