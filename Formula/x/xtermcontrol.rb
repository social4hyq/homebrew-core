class Xtermcontrol < Formula
  desc "Control xterm properties such as colors, title, font and geometry"
  homepage "https://thrysoee.dk/xtermcontrol/"
  url "https://thrysoee.dk/xtermcontrol/xtermcontrol-3.10.tar.gz"
  sha256 "3eb97b1d9d8aae1bad4fe2c41ca3a3dbb10d2d67e6ca4599aa1f631a40503dee"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?xtermcontrol[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9cc553f1f94613b10b94c79c7ee8d793d26e3075e4d9205aa3c0055857598e81"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xtermcontrol --version")

    expected = if OS.mac?
      "--get-fg is unsupported or disallowed by this terminal"
    else
      "failed to get controlling terminal"
    end

    ret_code = OS.mac? ? 0 : 1
    assert_match expected, shell_output("#{bin}/xtermcontrol --force --get-fg 2>&1", ret_code)
  end
end
