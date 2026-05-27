class Libdivsufsort < Formula
  desc "Lightweight suffix-sorting library"
  homepage "https://github.com/y-256/libdivsufsort"
  url "https://github.com/y-256/libdivsufsort/archive/refs/tags/2.0.1.tar.gz"
  sha256 "9164cb6044dcb6e430555721e3318d5a8f38871c2da9fd9256665746a69351e0"
  license "MIT"
  head "https://github.com/y-256/libdivsufsort.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b14156fe69c39aa697f31d5e2974e3401ef25640545f62e2dcbdc2e510ee3dcf"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DBUILD_EXAMPLES=OFF
      -DBUILD_DIVSUFSORT64=ON
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    expected_output = <<~EOS
      SA[ 0] = 10: a$
      SA[ 1] =  7: abra$
      SA[ 2] =  0: abracadabra$
      SA[ 3] =  3: acadabra$
      SA[ 4] =  5: adabra$
      SA[ 5] =  8: bra$
      SA[ 6] =  1: bracadabra$
      SA[ 7] =  4: cadabra$
      SA[ 8] =  6: dabra$
      SA[ 9] =  9: ra$
      SA[10] =  2: racadabra$
    EOS

    ["", "64"].each do |suffix|
      (testpath/"test#{suffix}.c").write <<~C
        #include <stdio.h>
        #include <stdlib.h>
        #include <string.h>
        #include <inttypes.h>
        #include <divsufsort#{suffix}.h>

        int main() {
            char *Text = "abracadabra";
            int n = strlen(Text);
            int i, j;

            saidx#{suffix}_t *SA = (saidx#{suffix}_t *) malloc(n * sizeof(saidx#{suffix}_t));
            divsufsort#{suffix}((unsigned char *) Text, SA, n);
            for (i = 0; i < n; ++i) {
                printf("SA[%2d] = %2" #{(suffix == "64") ? "PRId64" : "PRId32"} ": ", i, SA[i]);
                for(j = SA[i]; j < n; ++j) {
                    printf("%c", Text[j]);
                }
                printf("$\\n");
            }

            free(SA);
            return 0;
        }
      C

      system ENV.cc, "test#{suffix}.c", "-I#{include}", "-L#{lib}", "-ldivsufsort#{suffix}", "-o", "test#{suffix}"
      assert_equal expected_output, shell_output(testpath/"test#{suffix}")
    end
  end
end
