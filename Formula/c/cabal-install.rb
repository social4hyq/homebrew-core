class CabalInstall < Formula
  desc "Command-line interface for Cabal and Hackage"
  homepage "https://www.haskell.org/cabal/"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/haskell/cabal.git", branch: "master"

  stable do
    url "https://hackage.haskell.org/package/cabal-install-3.18.1.0/cabal-install-3.18.1.0.tar.gz"
    sha256 "7e5c3f5e53f7c91f9ff8f0fb075574e772562d0eeb400c402c7d9277558f0821"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4858e9298533b289a22fc2e32a39de611a52c17d6b5113b7c3adb9a74a5f1e83"
  end

  depends_on "ghc" => [:build, :test]
  depends_on "gmp"

  uses_from_macos "libffi"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Make sure bootstrap version supports GHC provided by Homebrew
  resource "bootstrap" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.2.0/cabal-install-3.14.2.0-aarch64-darwin.tar.xz"
        sha256 "c599c888c4c72731a2abbbab4c8443f9e604d511d947793864a4e9d7f9dfff83"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.2.0/cabal-install-3.14.2.0-x86_64-darwin.tar.xz"
        sha256 "f9d0cac59deeeb1d35f72f4aa7e5cba3bfe91d838e9ce69b8bc9fc855247ce0f"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.2.0/cabal-install-3.14.2.0-aarch64-linux-alpine3_18.tar.xz"
        sha256 "f2728933bb42aef1e202d946854140f2aa02f26a8c74f6aabb93932a79a6aec4"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.14.2.0/cabal-install-3.14.2.0-x86_64-linux-ubuntu20_04.tar.xz"
        sha256 "974a0c29cae721a150d5aa079a65f2e1c0843d1352ffe6aedd7594b176c3e1e6"
      end
    end
  end

  # resolv-0.2.0.3 C FFI uses glibc-specific `_res` global variable
  # which is not available on OpenHarmony (musl libc). We ship a patched copy.
  resource "resolv-src" do
    url "https://hackage.haskell.org/package/resolv-0.2.0.3/resolv-0.2.0.3.tar.gz"
    sha256 "7702a48ab88b2ccbb78d4c4748f70a0bca2347b603daa2eb8ab014439d577103"

    patch do
      file "Patches/cabal-install/0001-add-resolv-musl-support.patch"
    end
  end

  def install
    # Use patched resolv as a local package
    (buildpath/"vendor").mkpath
    resource("resolv-src").stage(buildpath/"vendor/resolv")
    (buildpath/"cabal.project").write <<~EOS
      packages: .
      packages: vendor/resolv
    EOS

    resource("bootstrap").stage(buildpath/"bin")
    cabal = buildpath/"bin/cabal"
    cd "cabal-install" if build.head?
    system cabal, "v2-update"
    system cabal, "v2-install", *std_cabal_v2_args
    bash_completion.install "bash-completion/cabal"
  end

  test do
    system bin/"cabal", "--config-file=#{testpath}/config", "user-config", "init"
    system bin/"cabal", "--config-file=#{testpath}/config", "v2-update"
    system bin/"cabal", "--config-file=#{testpath}/config", "info", "Cabal"
  end
end

