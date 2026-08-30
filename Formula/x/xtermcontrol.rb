class Xtermcontrol < Formula
  desc "Control xterm properties such as colors, title, font and geometry"
  homepage "https://thrysoee.dk/xtermcontrol/"
  url "https://thrysoee.dk/xtermcontrol/xtermcontrol-3.11.tar.gz"
  sha256 "49ea6d3eda0dbcf875363763cefe1818ce6786b9910255ea641d9786bdafd44c"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?xtermcontrol[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c3e7a93a9477ce5c6361e5e64fa5e3b618b02a068187851c8a7ee12816f089b2"
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
