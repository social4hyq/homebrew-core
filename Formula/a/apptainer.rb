class Apptainer < Formula
  desc "Application container and unprivileged sandbox platform for Linux"
  homepage "https://apptainer.org/"
  url "https://github.com/apptainer/apptainer/releases/download/v1.5.2/apptainer-1.5.2.tar.gz"
  sha256 "0dc689f4b1036941837f38376313082d953eec920520e295525d89e0f0e04f98"
  license "BSD-3-Clause"
  head "https://github.com/apptainer/apptainer.git", branch: "main"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "35c2d2fa2d37adf4bec3296265148c3834d09dccf7bd1aaf87cff588b977a42e"
  end

  # No relocation, the localstatedir to find configs etc is compiled into the program
  pour_bottle? only_if: :default_prefix

  depends_on "go" => :build
  depends_on "pkgconf" => :build
  depends_on "libseccomp"
  depends_on :linux
  depends_on "squashfs"

  def install
    ENV["CGO_ENABLED"] = "1" if Hardware::CPU.arm?

    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --without-suid
      -P release
      -v
    ]
    ENV.O0
    system "./mconfig", *args
    cd "./builddir" do
      system "make"
      system "make", "install"
    end

    generate_completions_from_executable(bin/"apptainer", shell_parameter_format: :cobra)
  end

  test do
    assert_match(/There are [0-9]+ container file/, shell_output("#{bin}/apptainer cache list"))
    # This does not work inside older github runners, but for a simple quick check, run:
    # singularity exec library://alpine cat /etc/alpine-release
  end
end
