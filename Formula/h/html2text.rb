class Html2text < Formula
  desc "Advanced HTML-to-text converter"
  homepage "https://gitlab.com/grobian/html2text"
  url "https://gitlab.com/-/project/48313341/uploads/8526650dd42218b3493ce7ca0a3eeb1e/html2text-2.4.0.tar.gz"
  sha256 "9d0a7174cacbb3f050b60facd8cba6e138944ec5020b16d1cee70cf91a59f132"
  license "GPL-2.0-or-later"
  head "https://gitlab.com/grobian/html2text.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5816bfc68700be408826f16ae9c2580c57d1a22b36684104f237ec6d7fe78f71"
  end

  def install
    # libiconv is not linked properly without this
    ENV.append "LDFLAGS", "-liconv" if OS.mac?

    ENV.cxx11
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    path = testpath/"index.html"
    path.write <<~HTML
      <!DOCTYPE html>
      <html>
        <head><title>Home</title></head>
        <body><p>Hello World</p></body>
      </html>
    HTML

    assert_equal "Hello World", shell_output("#{bin}/html2text #{path}").strip
  end
end
