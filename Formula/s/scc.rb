class Scc < Formula
  desc "Fast and accurate code counter with complexity and COCOMO estimates"
  homepage "https://github.com/boyter/scc/"
  url "https://github.com/boyter/scc/archive/refs/tags/v3.7.0.tar.gz"
  sha256 "447233f70ebcc24f1dafb27b093afdd17d3a1d662de96e8226130c5308b02d01"
  license any_of: ["MIT", "Unlicense"]

  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1d083c984fc95d77c572a14835bf5f044c878fca63dc34de95911da232a5b50a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    generate_completions_from_executable(bin/"scc", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/scc --version")

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      int main(void) {
        return 0;
      }
    C

    expected_output = <<~EOS
      Language,Lines,Code,Comments,Blanks,Complexity,Bytes,Files,ULOC
      C,4,4,0,0,0,50,1,0
    EOS

    assert_match expected_output, shell_output("#{bin}/scc -fcsv test.c")
  end
end
