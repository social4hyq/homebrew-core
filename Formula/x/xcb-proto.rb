class XcbProto < Formula
  desc "X.Org: XML-XCB protocol descriptions for libxcb code generation"
  homepage "https://www.x.org/"
  url "https://xorg.freedesktop.org/archive/individual/proto/xcb-proto-1.17.0.tar.xz"
  sha256 "2c1bacd2110f4799f74de6ebb714b94cf6f80fb112316b1219480fd22562148c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "968492856cc719d6fbcc91124696891e607746acda6863b88862e953e0a6fc4f"
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "python@3.14" => [:build, :test]

  def python3
    "python3.14"
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      PYTHON=#{python3}
    ]

    system "./configure", *args
    system "make"
    system "make", "install"
  end

  test do
    assert_match "#{share}/xcb", shell_output("pkg-config --variable=xcbincludedir xcb-proto").chomp
    system python3, "-c", <<~PYTHON
      import collections
      output = collections.defaultdict(int)
      from xcbgen import xtypes
    PYTHON
  end
end
