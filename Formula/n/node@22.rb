class NodeAT22 < Formula
  desc "Open-source, cross-platform JavaScript runtime environment"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v22.23.1/node-v22.23.1.tar.xz"
  sha256 "b27385d6845089bdb91285d94b06c2a5cf1c37f8173a3c4e10824cc1ffadeaba"
  license "MIT"
  compatibility_version 1

  livecheck do
    url "https://nodejs.org/dist/"
    regex(%r{href=["']?v?(22(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "538b43efa542d3b21a2109023f461492e28fbba0ed65b08a25a07aaf4ecbaec6"
  end

  keg_only :versioned_formula

  # https://github.com/nodejs/release#release-schedule
  # disable! date: "2027-04-30", because: :unsupported
  deprecate! date: "2026-10-28", because: :unsupported

  resource "alpine-rootfs" do
    url "https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/aarch64/alpine-minirootfs-3.23.4-aarch64.tar.gz"
    sha256 "9250667a8affac8f1e98086392f80f43f086626701e9bce33398eb9b6c0bd64c"
  end

  def install
    # Although node@22 can be compiled with the ohos-sdk compiler (LLVM 15),
    # we use the Alpine native GCC and static linking here instead.
    # This maintains consistency with the node and node@24 formulae.

    chroot_dir = buildpath/"alpine-chroot"
    chroot_dir.mkpath

    resource("alpine-rootfs").stage do
      system "cp", "-a", ".", chroot_dir.to_s
    end

    if File.exist?("/etc/resolv.conf")
      chroot_dir.join("etc/resolv.conf").write(File.read("/etc/resolv.conf"))
    else
      chroot_dir.join("etc/resolv.conf").write("nameserver 8.8.8.8\n")
    end

    chroot_build_dir = chroot_dir/"build"
    chroot_build_dir.mkpath

    Dir.glob("#{buildpath}/*").each do |file|
      next if file == chroot_dir.to_s
      FileUtils.mv(file, chroot_build_dir)
    end

    chroot_script = <<~SH
      set -e
      export PATH=/bin:/usr/bin:/usr:sbin
      export HOME=/root

      apk update
      apk add build-base python3 linux-headers

      cd /build
      sed -i 's/linux /linux openharmony /g' common_node.gypi
      export CC="gcc"
      export CXX="g++"
      ./configure \
        --prefix=#{prefix} \
        --dest-os=openharmony \
        --partly-static

      make -j$(nproc)
      mkdir -p /dest
      make install DESTDIR=/dest
    SH

    chroot_dir.join("build_node.sh").write(chroot_script)
    system "chmod", "+x", "#{chroot_dir}/build_node.sh"

    system "env", "-i", "chroot", chroot_dir.to_s, "/bin/sh", "/build_node.sh"

    chroot_dest_target = chroot_dir/"dest#{prefix}"
    cd chroot_dest_target do
      prefix.install Dir["*"]
    end
  end

  def post_install
    (lib/"node_modules/npm/npmrc").atomic_write("prefix = #{HOMEBREW_PREFIX}\n")
  end

  test do
    # Make sure Mojave does not have `CC=llvm_clang`.
    ENV.clang if OS.mac?

    path = testpath/"test.js"
    path.write "console.log('hello');"

    output = shell_output("#{bin}/node #{path}").strip
    assert_equal "hello", output
    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"en-EN\").format(1234.56))'").strip
    assert_equal "1,234.56", output

    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"de-DE\").format(1234.56))'").strip
    assert_equal "1.234,56", output

    # make sure npm can find node
    ENV.prepend_path "PATH", opt_bin
    ENV.delete "NVM_NODEJS_ORG_MIRROR"
    assert_equal which("node"), opt_bin/"node"
    assert_path_exists bin/"npm", "npm must exist"
    assert_predicate bin/"npm", :executable?, "npm must be executable"
    npm_args = ["-ddd", "--cache=#{HOMEBREW_CACHE}/npm_cache", "--build-from-source"]
    system bin/"npm", *npm_args, "install", "npm@latest"
    system bin/"npm", *npm_args, "install", "nan"
    assert_path_exists bin/"npx", "npx must exist"
    assert_predicate bin/"npx", :executable?, "npx must be executable"
    assert_match "< hello >", shell_output("#{bin}/npx --yes cowsay hello")
  end
end
