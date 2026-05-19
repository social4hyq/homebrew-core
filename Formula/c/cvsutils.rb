class Cvsutils < Formula
  desc "CVS utilities for use in working directories"
  homepage "https://www.red-bean.com/cvsutils/"
  url "https://www.red-bean.com/cvsutils/releases/cvsutils-0.2.6.tar.gz"
  sha256 "174bb632c4ed812a57225a73ecab5293fcbab0368c454d113bf3c039722695bb"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.red-bean.com/cvsutils/releases/"
    regex(/href=.*?cvsutils[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "115f3505113f66b12b8413d5b989b3cbaab262d46ff13d9f409fe5e77a67f19f"
  end

  uses_from_macos "perl"

  def install
    ENV["CONFIG_SHELL"] = "/bin/bash" # for all bottle
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"cvsu", "--help"
  end
end
