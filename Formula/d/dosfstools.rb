class Dosfstools < Formula
  desc "Tools to create, check and label file systems of the FAT family"
  homepage "https://github.com/dosfstools"
  license "GPL-3.0-or-later"
  head "https://github.com/dosfstools/dosfstools.git", branch: "master"

  stable do
    url "https://github.com/dosfstools/dosfstools/releases/download/v4.2/dosfstools-4.2.tar.gz"
    sha256 "64926eebf90092dca21b14259a5301b7b98e7b1943e8a201c7d726084809b527"

    # remove in next release
    # https://github.com/dosfstools/dosfstools/pull/166
    patch do
      url "https://github.com/dosfstools/dosfstools/commit/77ffb87e8272760b3bb2dec8f722103b0effb801.patch?full_index=1"
      sha256 "ecbd911eae51ed382729cd1fb84d4841b3e1e842d08e45b05d61f41fbd0a88ff"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4289eb67c5287376f31e8af1750adbb5ff745eec800c7057efdf7ccf9d5b00e9"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gettext" => :build
  depends_on "pkgconf" => :build

  def install
    # Workaround for https://github.com/dosfstools/dosfstools/pull/218
    ENV.append_path "ACLOCAL_PATH", Formula["gettext"].pkgshare/"m4"

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--enable-compat-symlinks",
                          "--without-udev",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system "dd", "if=/dev/zero", "of=test.bin", "bs=512", "count=1024"
    system sbin/"mkfs.fat", "test.bin", "-n", "HOMEBREW", "-v"
    system sbin/"fatlabel", "test.bin"
    system sbin/"fsck.fat", "-v", "test.bin"
  end
end
