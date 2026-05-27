class Exif < Formula
  desc "Read, write, modify, and display EXIF data on the command-line"
  homepage "https://libexif.github.io/"
  url "https://github.com/libexif/exif/releases/download/exif-0_6_22-release/exif-0.6.22.tar.xz"
  sha256 "0fe268736e0ca0538d4af941022761a438854a64c8024a4175e57bf0418117b9"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    regex(/^exif[._-]v?(\d+(?:[._-]\d+)+)[._-]release$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "648d5f23adff37fcdf124746ebd4327900ed38beb499449cf539ce049bf00d09"
  end

  depends_on "pkgconf" => :build
  depends_on "libexif"
  depends_on "popt"

  def install
    args = %w[
      --disable-silent-rules
      --disable-nls
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    test_image = test_fixtures("test.jpg")
    assert_match "The data supplied does not seem to contain EXIF data.",
                 shell_output("#{bin}/exif #{test_image} 2>&1", 1)
  end
end
