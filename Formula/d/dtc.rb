class Dtc < Formula
  desc "Device tree compiler"
  homepage "https://git.kernel.org/pub/scm/utils/dtc/dtc.git"
  url "https://mirrors.edge.kernel.org/pub/software/utils/dtc/dtc-1.8.1.tar.xz"
  sha256 "23526015a6f1550e0541a53fe7acea1b5a11e3697cdf3a3bdc076abc38f6045d"
  license any_of: ["GPL-2.0-or-later", "BSD-2-Clause"]
  compatibility_version 1
  head "https://git.kernel.org/pub/scm/utils/dtc/dtc.git", branch: "master"

  livecheck do
    url "https://mirrors.edge.kernel.org/pub/software/utils/dtc/"
    regex(/href=.*?dtc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/dtc-v1.8.1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cb8323d82f1b65d666905a02503bd25fee1fbe913a2d24b94972ee9c988a5c76"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  depends_on "libyaml"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  def install
    args = %w[
      -Dpython=disabled
      -Dtests=false
      -Dvalgrind=disabled
      -Dwerror=false
      -Dyaml=enabled
    ]

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.dts").write <<~EOS
      /dts-v1/;
      / {
      };
    EOS
    system bin/"dtc", "test.dts"
  end
end
