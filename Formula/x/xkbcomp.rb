class Xkbcomp < Formula
  desc "XKB keyboard description compiler"
  homepage "https://www.x.org"
  url "https://www.x.org/releases/individual/app/xkbcomp-1.5.0.tar.xz"
  sha256 "2ac31f26600776db6d9cd79b3fcd272263faebac7eb85fb2f33c7141b8486060"
  license all_of: ["HPND", "MIT-open-group"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "59c731c58869359fd8632901ebb9073d0c203c1a03d699c83875a36c8c9cb1bd"
  end

  depends_on "pkgconf" => :build

  depends_on "libx11"
  depends_on "libxkbfile"

  def install
    system "./configure", "--with-xkb-config-root=#{HOMEBREW_PREFIX}/share/X11/xkb", *std_configure_args
    system "make"
    system "make", "install"
    # avoid cellar in bindir
    inreplace lib/"pkgconfig/xkbcomp.pc", prefix, opt_prefix
  end

  test do
    (testpath/"test.xkb").write <<~EOS
      xkb_keymap {
        xkb_keycodes "empty+aliases(qwerty)" {
          minimum = 8;
          maximum = 255;
          virtual indicator 1 = "Caps Lock";
        };
        xkb_types "complete" {};
        xkb_symbols "unknown" {};
        xkb_compatibility "complete" {};
      };
    EOS

    system bin/"xkbcomp", "./test.xkb"
    assert_path_exists testpath/"test.xkm"
  end
end
