class Liblc3 < Formula
  desc "Low Complexity Communication Codec library and tools"
  homepage "https://github.com/google/liblc3"
  url "https://github.com/google/liblc3/archive/refs/tags/v1.1.3.tar.gz"
  sha256 "276752ff54ce6a77d54ec133397b9d7e71f90caf3d9afa32d8b0e891b8ecb8af"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "89954fb29242a876e4d0f309c2a239c0768b2149cb9117d9398639bfdd5d0e2d"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  uses_from_macos "python"

  def install
    # disable tools build due to rpath issue, see https://github.com/google/liblc3/pull/53
    args = %w[
      -Dtools=false
      -Dpython=true
    ]

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "lc3.h"
      #include <stdio.h>
      #include <stdlib.h>

      int main() {
          int frame_duration_us = 10000; // 10 ms frame duration
          int sample_rate_hz = 48000;    // 48 kHz sample rate

          // Memory allocation for encoder and decoder
          size_t encoder_mem_size = lc3_encoder_size(frame_duration_us, sample_rate_hz);
          void* encoder_mem = malloc(encoder_mem_size);
          if (!encoder_mem) {
              printf("Failed to allocate memory for the encoder.\\n");
              return 1;
          }

          size_t decoder_mem_size = lc3_decoder_size(frame_duration_us, sample_rate_hz);
          void* decoder_mem = malloc(decoder_mem_size);
          if (!decoder_mem) {
              printf("Failed to allocate memory for the decoder.\\n");
              free(encoder_mem);
              return 1;
          }

          // Setup encoder and decoder
          lc3_encoder_t encoder = lc3_setup_encoder(frame_duration_us, sample_rate_hz, 0, encoder_mem);
          if (!encoder) {
              printf("Failed to setup the encoder.\\n");
              free(encoder_mem);
              free(decoder_mem);
              return 1;
          }

          lc3_decoder_t decoder = lc3_setup_decoder(frame_duration_us, sample_rate_hz, 0, decoder_mem);
          if (!decoder) {
              printf("Failed to setup the decoder.\\n");
              free(encoder_mem);
              free(decoder_mem);
              return 1;
          }

          printf("LC3 encoder and decoder setup was successful.\\n");

          free(encoder_mem);
          free(decoder_mem);
          printf("Cleanup completed.\\n");

          return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-llc3", "-o", "test"
    system "./test"
  end
end
