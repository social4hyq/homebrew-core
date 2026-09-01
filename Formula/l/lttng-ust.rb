class LttngUst < Formula
  desc "Linux Trace Toolkit Next Generation Userspace Tracer"
  homepage "https://lttng.org/"
  url "https://lttng.org/files/lttng-ust/lttng-ust-2.16.0.tar.bz2"
  sha256 "1e84e02fa1fc1261eb6cf3d14d64006506a29f7c605ac85de02180318c6aa38a"
  license all_of: ["LGPL-2.1-only", "MIT", "GPL-2.0-only", "BSD-3-Clause", "BSD-2-Clause", "GPL-3.0-or-later"]

  livecheck do
    url "https://lttng.org/download/"
    regex(/href=.*?lttng-ust[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60891e129c2f055b8d588a193dd1a37bd21f342a89b6dc2916a7df2fc7589bca"
  end

  depends_on "pkgconf" => :build
  depends_on :linux
  depends_on "numactl"
  depends_on "userspace-rcu"

  # OpenHarmony: the dynamic linker may not support dlclose at destructor time.
  # Skip abort() and let the OS reclaim resources at process exit.
  patch do
    file "Patches/lttng-ust/0001-ohos-skip-dlclose-abort-on-OHOS.patch"
  end

  def install
    # lld on OHOS defaults to --no-allow-shlib-undefined which is stricter than GNU ld.
    # Shared libraries may reference pthread symbols resolved at runtime.
    ENV.append "LDFLAGS", "-Wl,--allow-shlib-undefined"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    cp_r (share/"doc/lttng-ust/examples/demo").children, testpath
    system "make"
    system "./demo"
  end
end
