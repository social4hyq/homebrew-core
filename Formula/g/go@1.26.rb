class GoAT126 < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  url "https://go.dev/dl/go1.26.8.src.tar.gz"
  mirror "https://fossies.org/linux/misc/go1.26.8.src.tar.gz"
  sha256 "4e39b98e42f946fa05ac8bc5b71877df97dbdb7cbb1a777b541667ad7117fd2e"
  license "BSD-3-Clause"
  compatibility_version 1

  livecheck do
    url "https://go.dev/dl/?mode=json"
    regex(/^go[._-]?v?(1\.26(?:\.\d+)*)[._-]src\.t.+$/i)
    strategy :json do |json, regex|
      json.map do |release|
        next if release["stable"] != true
        next if release["files"].none? { |file| file["filename"].match?(regex) }

        release["version"][/(\d+(?:\.\d+)+)/, 1]
      end
    end
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fab7d8b6a740dc4413457f8391fc9307329bdfdda8ac444474a9ed9d76624fe4"
  end

  keg_only :versioned_formula

  depends_on "go" => :build

  # ═══════════════════════════════════════════════════════════════════
  # HarmonyOS patches
  #
  # Problem: On HarmonyOS PC, hmdfs does not support mmap(PROT_WRITE)
  # causing linker failures. Also, compiled ELF binaries require code
  # signing to execute.
  #
  #   0001: Default GOCACHE → /data/storage/el2/base/files/go-build (hmfs)
  #   0002: Default GOTMPDIR → /data/storage/el2/base/cache (tmpfs)
  #   0003: Vendored selfsign.go (byte-identical to ohos-selfsign, kept
  #         in its own patch so it can be upgraded independently)
  #   0004: Adapt vendored selfsign.go to an importable library
  #         (package main → selfsign, export API, drop main())
  #   0005: Auto-sign ELF binaries after buildid -w (in cmd/go, not linker);
  #         treats selfsign.go as a library (import + call)
  # ═══════════════════════════════════════════════════════════════════

  patch do
    file "Patches/go@1.26/0001-gocache-default.patch"
  end

  patch do
    file "Patches/go@1.26/0002-gotmpdir-default.patch"
  end

  patch do
    file "Patches/go@1.26/0003-vendor-selfsign-go.patch"
  end

  patch do
    file "Patches/go@1.26/0004-export-selfsign-lib.patch"
  end

  patch do
    file "Patches/go@1.26/0005-auto-sign-elf.patch"
  end

  def install
    libexec.install Dir["*"]

    cd libexec/"src" do
      # Set portable defaults for CC/CXX to be used by cgo
      with_env(CC: "cc", CXX: "c++") { system "./make.bash" }
    end

    bin.install_symlink Dir[libexec/"bin/go*"]

    # Remove useless files.
    # Breaks patchelf because folder contains weird debug/test files
    rm_r(libexec/"src/debug/elf/testdata")
    # Binaries built for an incompatible architecture
    rm_r(libexec/"src/runtime/pprof/testdata")
    # Remove testdata with binaries for non-native architectures.
    rm_r(libexec/"src/debug/dwarf/testdata")
  end

  test do
    (testpath/"hello.go").write <<~GO
      package main

      import "fmt"

      func main() {
          fmt.Println("Hello World")
      }
    GO

    # Run go fmt check for no errors then run the program.
    # This is a a bare minimum of go working as it uses fmt, build, and run.
    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

    with_env(GOOS: "freebsd", GOARCH: "amd64") do
      system bin/"go", "build", "hello.go"
    end

    (testpath/"hello_cgo.go").write <<~GO
      package main

      /*
      #include <stdlib.h>
      #include <stdio.h>
      void hello() { printf("%s\\n", "Hello from cgo!"); fflush(stdout); }
      */
      import "C"

      func main() {
          C.hello()
      }
    GO

    # Try running a sample using cgo without CC or CXX set to ensure that the
    # toolchain's default choice of compilers work
    with_env(CC: nil, CXX: nil, CGO_ENABLED: "1") do
      assert_equal "Hello from cgo!\n", shell_output("#{bin}/go run hello_cgo.go")
    end
  end
end
