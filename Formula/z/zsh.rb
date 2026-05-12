class Zsh < Formula
  desc "UNIX shell (command interpreter)"
  homepage "https://www.zsh.org/"
  license all_of: [
    "MIT-Modern-Variant",
    "GPL-2.0-only", # Completion/Linux/Command/_qdbus, Completion/openSUSE/Command/{_osc,_zypper}
    "GPL-2.0-or-later", # Completion/Unix/Command/_darcs
    "ISC", # Src/openssh_bsd_setres_id.c
  ]

  stable do
    url "https://downloads.sourceforge.net/project/zsh/zsh/5.9/zsh-5.9.tar.xz"
    mirror "https://www.zsh.org/pub/zsh-5.9.tar.xz"
    sha256 "9b8d1ecedd5b5e81fbf1918e876752a7dd948e05c1a0dba10ab863842d45acd5"

    depends_on "autoconf" => :build # TODO: Remove on the next release

    resource "htmldoc" do
      url "https://downloads.sourceforge.net/project/zsh/zsh-doc/5.9/zsh-5.9-doc.tar.xz"
      mirror "https://www.zsh.org/pub/zsh-5.9-doc.tar.xz"
      sha256 "6f7c091249575e68c177c5e8d5c3e9705660d0d3ca1647aea365fd00a0bd3e8a"

      livecheck do
        formula :parent
      end
    end

    # Use Debian patches to backport `pcre2` support:
    # * https://github.com/zsh-users/zsh/commit/b62e911341c8ec7446378b477c47da4256053dc0
    # * https://github.com/zsh-users/zsh/commit/10bdbd8b5b0b43445aff23dcd412f25cf6aa328a
    patch do
      url "https://sources.debian.org/data/main/z/zsh/5.9-8/debian/patches/cherry-pick-b62e91134-51723-migrate-pcre-module-to-pcre2.patch"
      sha256 "9bd45e1262856e22f28c5d6ec1e1584e4f8add3270bbf68ee06aabb0ee24d745"
    end
    patch do
      url "https://sources.debian.org/data/main/z/zsh/5.9-8/debian/patches/cherry-pick-10bdbd8b-51877-do-not-build-pcre-module-if-pcre2-config-is-not-found.patch"
      sha256 "fe9e2bd42e5405995750b30f32f8dc02135c6cf55c0889018d68af114ffa78da"
    end
  end

  livecheck do
    url "https://sourceforge.net/projects/zsh/rss?path=/zsh"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56d18b43ad74aa48bc5dac3bbb46b7525b67add4e13aa0e7cc4ff6e7489e4593"
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

    odie "Update build to run Utils/preconfig only on HEAD!" if build.stable? && version > "5.9"
    system "Util/preconfig" # TODO: if build.head?

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
      system "make", "install.info"

      resource("htmldoc").stage do
        (pkgshare/"htmldoc").install Dir["Doc/*.html"]
      end
    end
  end

  test do
    assert_equal "homebrew", shell_output("#{bin}/zsh -c 'echo homebrew'").chomp
    system bin/"zsh", "-c", "printf -v hello -- '%s'"
    system bin/"zsh", "-c", "zmodload zsh/pcre"
  end
end
