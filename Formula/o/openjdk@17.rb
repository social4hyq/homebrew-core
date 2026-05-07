class OpenjdkAT17 < Formula
  desc "Development kit for the Java programming language"
  homepage "https://openjdk.org/"
  url "https://github.com/openjdk/jdk17u/archive/refs/tags/jdk-17.0.19-ga.tar.gz"
  sha256 "b165f0dd120f4455904b76cf87dd9352fd23f88c2e9a33c2532fabacc3cca962"
  license "GPL-2.0-only" => { with: "Classpath-exception-2.0" }
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^jdk[._-]v?(17(?:\.\d+)*)-ga$/i)
  end

  bottle do
    sha256 cellar: :any, arm64_tahoe:   "6d51e51e754dc75437c5c552eea568ec2f166e39fc3faa256e668083a8620c17"
    sha256 cellar: :any, arm64_sequoia: "5544476e1a2a6d9e449c637e4224513091ff97ee63896aca161175a041ad3a14"
    sha256 cellar: :any, arm64_sonoma:  "b95d5e34016e8839a15ea90d2c9f74365424df4c98911d4e7f42ab05c7b160ec"
    sha256 cellar: :any, sonoma:        "4d13b59638a205d7a77bf2a20907fafe0344e39f479648732216b67b1eb93a36"
    sha256               arm64_linux:   "b4d4eb0b9925ed74487a0e44fdff65eea0f13d317b4508cc44f13ca1f54b2e4f"
    sha256               x86_64_linux:  "586ff683171f8b5c61705128337a497b35c06081df4146b0b8a64ac1ebd8cd7b"
  end

  deprecate! date: "2026-09-30", because: :unmaintained
  disable! date: "2029-09-30", because: :unmaintained

  depends_on "autoconf" => :build
  depends_on "pkgconf" => :build
  depends_on xcode: :build # for metal

  uses_from_macos "cups"
  uses_from_macos "unzip"
  uses_from_macos "zip"

  on_linux do
    depends_on "alsa-lib"
    depends_on "fontconfig"
    depends_on "libx11"
    depends_on "libxext"
    depends_on "libxi"
    depends_on "libxrandr"
    depends_on "libxrender"
    depends_on "libxt"
    depends_on "libxtst"
    depends_on "zlib-ng-compat"
  end

  # From BellSoft
  # BellSoft is one of the most trusted and mainstream vendors in the OpenJDK community.
  resource "boot-jdk" do
    on_linux do
      on_arm do
        url "https://download.bell-sw.com/java/17.0.18+10/bellsoft-jdk17.0.18+10-linux-aarch64-musl.tar.gz"
        sha256 "ed7251cd91a979ed5bb6c6beff3c4fc458eb0efd85c8cf71ec64fb783f15fb38"
      end
    end
  end

  patch do
    url "https://raw.gitcode.com/Harmonybrew/homebrew-core/raw/main/Patches/openjdk@17/0001-support-ohos.patch"
    sha256 "bce5e3d437b0c8bc2ac2f2c30d5d76a29242780c61054a4439305c917a65a8ea"
  end

  def install
    boot_jdk = buildpath/"boot-jdk"
    resource("boot-jdk").stage boot_jdk
    boot_jdk /= "Contents/Home" if OS.mac?
    java_options = ENV.delete("_JAVA_OPTIONS")

    # For boot-jdk
    ENV.prepend_path "LD_LIBRARY_PATH", "#{HOMEBREW_PREFIX}/lib"

    args = %W[
      --disable-warnings-as-errors
      --with-boot-jdk-jvmargs=#{java_options}
      --with-boot-jdk=#{boot_jdk}
      --with-debug-level=release
      --with-jvm-variants=server
      --with-native-debug-symbols=none
      --with-vendor-bug-url=#{tap.issues_url}
      --with-vendor-name=#{tap.user}
      --with-vendor-url=#{tap.issues_url}
      --with-vendor-version-string=#{tap.user}
      --with-vendor-vm-bug-url=#{tap.issues_url}
      --with-version-build=#{revision}
      --without-version-opt
      --without-version-pre
      --with-zlib=system
      --enable-ohos=yes
      --enable-headless-only=yes
      --with-copyright-year=2026
      --with-toolchain-type=clang
      --host=aarch64-unknown-linux-musl
    ]

    ldflags = ["-Wl,-rpath,#{loader_path.gsub("$", "\\$$")}/server"]
    args += if OS.mac?
      ldflags << "-headerpad_max_install_names"

      # Allow unbundling `freetype` on macOS
      inreplace "make/autoconf/lib-freetype.m4", '= "xmacosx"', '= ""'

      %W[
        --enable-dtrace
        --with-freetype-include=#{Formula["freetype"].opt_include}
        --with-freetype-lib=#{Formula["freetype"].opt_lib}
        --with-sysroot=#{MacOS.sdk_path}
      ]
    else
      %W[
        --with-x=#{HOMEBREW_PREFIX}
        --with-cups=#{HOMEBREW_PREFIX}
        --with-fontconfig=#{HOMEBREW_PREFIX}
        --with-stdc++lib=dynamic
      ]
    end
    args << "--with-extra-ldflags=#{ldflags.join(" ")}"

    if DevelopmentTools.clang_build_version == 1600 && MacOS::Xcode.version < "16.2"
      args << "--with-extra-cflags=-mllvm -enable-constraint-elimination=0"
    end

    system "bash", "configure", *args

    ENV["MAKEFLAGS"] = "JOBS=#{ENV.make_jobs}"
    system "make", "images"

    jdk = libexec
    if OS.mac?
      libexec.install Dir["build/*/images/jdk-bundle/*"].first => "openjdk.jdk"
      jdk /= "openjdk.jdk/Contents/Home"
    else
      libexec.install Dir["build/linux-*-server-release/images/jdk/*"]
    end

    bin.install_symlink Dir[jdk/"bin/*"]
    include.install_symlink Dir[jdk/"include/*.h"]
    include.install_symlink Dir[jdk/"include"/OS.kernel_name.downcase/"*.h"]
    man1.install_symlink Dir[jdk/"man/man1/*"]
  end

  def caveats
    on_macos do
      <<~EOS
        For the system Java wrappers to find this JDK, symlink it with
          sudo ln -sfn #{opt_libexec}/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
      EOS
    end
  end

  test do
    (testpath/"HelloWorld.java").write <<~JAVA
      class HelloWorld {
        public static void main(String args[]) {
          System.out.println("Hello, world!");
        }
      }
    JAVA

    system bin/"javac", "HelloWorld.java"

    assert_match "Hello, world!", shell_output("#{bin}/java HelloWorld")
  end
end
