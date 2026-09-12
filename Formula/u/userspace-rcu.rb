class UserspaceRcu < Formula
  desc "Library for userspace RCU (read-copy-update)"
  homepage "https://liburcu.org"
  url "https://lttng.org/files/urcu/userspace-rcu-0.15.7.tar.bz2"
  sha256 "2556b83adc0f9b3ac8024e613e17d014d04c4c49110604ce55fcb14eae32edd3"
  license all_of: ["LGPL-2.1-or-later", "MIT"]
  compatibility_version 1

  livecheck do
    url "https://lttng.org/files/urcu/"
    regex(/href=.*?userspace-rcu[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f4f9a2a9d1362bc1705a5667ec60f7ee6b53752e959dafa64a8b279d4dad9589"
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args.reject { |s| s["disable-debug"] }
    system "make", "install"
  end

  test do
    cp_r doc/"examples", testpath
    system "make", "CFLAGS=-pthread", "-C", "examples"
  end
end
