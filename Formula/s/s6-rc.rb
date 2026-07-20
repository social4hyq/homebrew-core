class S6Rc < Formula
  desc "Process supervision suite"
  homepage "https://skarnet.org/software/s6-rc/"
  url "https://skarnet.org/software/s6-rc/s6-rc-0.7.0.0.tar.gz"
  sha256 "bf5b8ce0da5a4ee70d642b818b61d9916a7a9b64a457595f388113e54a188688"
  license "ISC"
  head "git://git.skarnet.org/s6-rc.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab62ce50ace3203efa375427f7a521ae99b7062c799f057097be1c5552921bef"
  end

  depends_on "pkgconf" => :build
  depends_on "execline"
  depends_on "s6"
  depends_on "skalibs"

  def install
    # Shared libraries are linux targets and not supported on macOS.
    args = %W[
      --disable-silent-rules
      --disable-shared
      --enable-pkgconfig
      --with-pkgconfig=#{Formula["pkgconf"].opt_bin}/pkg-config
      --with-sysdeps=#{Formula["skalibs"].opt_lib}/skalibs/sysdeps
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"services/test").mkpath
    (testpath/"services/test/up").write <<~SHELL
      #!/bin/sh
      echo "test"
    SHELL
    (testpath/"services/test/type").write "oneshot"
    (testpath/"services/bundle/contents.d").mkpath
    (testpath/"services/bundle/type").write "bundle"
    touch testpath/"services/bundle/contents.d/test"
    system bin/"s6-rc-compile", testpath/"compiled", testpath/"services"
  end
end
