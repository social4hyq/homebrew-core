class Openjdk < Formula
  desc "Development kit for the Java programming language"
  homepage "https://openjdk.org/"
  url "https://github.com/openjdk/jdk25u/archive/refs/tags/jdk-25.0.2-ga.tar.gz"
  sha256 "e4b935e999a28ee732dfb932dcef4a8591b42f6fcd182099319db68e9d8017ff"
  license "GPL-2.0-only" => { with: "Classpath-exception-2.0" }
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^jdk[._-]v?(\d+(?:\.\d+)*)-ga$/i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any, arm64_tahoe:   "5c33d6c93e3f80a9571ba06fce035f8e4e16d91a98df91995992f30416c3deb4"
    sha256 cellar: :any, arm64_sequoia: "86ab294dfd1dbe68caf67107af3928b4df5b4f2939f102be20a198eca743c1e2"
    sha256 cellar: :any, arm64_sonoma:  "75d25e5430e8bd4ce24180e249561b1b9f81f3a1ca578773ed086d4c9383d26e"
    sha256 cellar: :any, sonoma:        "16dc0565951675ec4a1951e9b948c8839fb1d8ffd964707ba5fc334f218c4dcf"
    sha256               arm64_linux:   "cd6261f09d923dfa6d384f07863f5ced901cf8e3e7b79637e44d474fcc935086"
    sha256               x86_64_linux:  "ceea61856c6c9f861c7c0662c3051a428a9870c99d2c14fd2429621ebf82acdc"
  end

  keg_only :shadowed_by_macos

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
        url "https://download.bell-sw.com/java/25.0.3+11/bellsoft-jdk25.0.3+11-linux-aarch64-musl.tar.gz"
        sha256 "7f00976d3ee57be1021a4fa94101ff598f6a4367f330080723301fa71faf2645"
      end
    end
  end

  patch do
    file "Patches/openjdk/0001-support-ohos.patch"
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
      --enable-headless-only=yes
      --with-copyright-year=2026
      --with-toolchain-type=clang
      --host=aarch64-unknown-linux-musl
      --with-extra-cxxflags="-DSIGEV_THREAD_ID=4"
    ]

    ldflags = %W[
      -Wl,-rpath,#{loader_path.gsub("$", "\\$$")}
      -Wl,-rpath,#{loader_path.gsub("$", "\\$$")}/server
    ]
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

    # Workaround for Xcode 16 bug: https://bugs.openjdk.org/browse/JDK-8340341.
    if DevelopmentTools.clang_build_version == 1600
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
          sudo ln -sfn #{opt_libexec}/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
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
