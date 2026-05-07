class AlsaLib < Formula
  desc "Provides audio and MIDI functionality to the Linux operating system"
  homepage "https://www.alsa-project.org/"
  url "https://www.alsa-project.org/files/pub/lib/alsa-lib-1.2.15.3.tar.bz2"
  sha256 "7b079d614d582cade7ab8db2364e65271d0877a37df8757ac4ac0c8970be861e"
  license all_of: ["LGPL-2.1-or-later", "GPL-2.0-or-later"]
  compatibility_version 1

  livecheck do
    url "https://www.alsa-project.org/files/pub/lib/"
    regex(/href=.*?alsa-lib[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "33ec1e808080d587d28ff616b7dca6b128ced5c0a84ba854131ea0cc68af2197"
  end

  depends_on :linux

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
    prefix.install "aserver/COPYING" => "COPYING-aserver"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <alsa/asoundlib.h>
      int main(void)
      {
          snd_ctl_card_info_t *info;
          snd_ctl_card_info_alloca(&info);
          return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lasound", "-o", "test"
    system "./test"
  end
end
