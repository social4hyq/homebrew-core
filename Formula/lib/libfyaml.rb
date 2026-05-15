class Libfyaml < Formula
  desc "Fully feature complete YAML parser and emitter"
  homepage "https://github.com/pantoniou/libfyaml"
  url "https://github.com/pantoniou/libfyaml/releases/download/v0.9.6/libfyaml-0.9.6.tar.gz"
  sha256 "a59cc3331e2eb903ec36933ad52a45888041cac31e44f553a00511131242c483"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfd648ba520adfe3ebbfe4f7853170c5be84fe041d8406a3fd2ee26c21a316ac"
  end

  uses_from_macos "m4" => :build

  # TODO: Remove patch when https://github.com/pantoniou/libfyaml/pull/267 is merged
  patch do
    url "https://github.com/pantoniou/libfyaml/commit/45faa819b6c3eb54b2d63b46d4c7690fa1e8e8ff.patch?full_index=1"
    sha256 "22fbbb360b96cf879397f1ab3dadf8876277f8d77708b6252c0908d37e09a4f9"
  end

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #ifdef HAVE_CONFIG_H
      #include "config.h"
      #endif

      #include <iostream>
      #include <libfyaml.h>

      int main(int argc, char *argv[])
      {
        std::cout << fy_library_version() << std::endl;
        return EXIT_SUCCESS;
      }
    CPP
    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-lfyaml", "-o", "test"
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_equal version.to_s, shell_output("#{testpath}/test").strip
    assert_equal version.to_s, shell_output("#{bin}/fy-tool --version").strip
  end
end
