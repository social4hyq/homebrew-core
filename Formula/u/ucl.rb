class Ucl < Formula
  desc "Data compression library with small memory footprint"
  homepage "https://www.oberhumer.com/opensource/ucl/"
  url "https://www.oberhumer.com/opensource/ucl/download/ucl-1.03.tar.gz"
  sha256 "b865299ffd45d73412293369c9754b07637680e5c826915f097577cd27350348"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.oberhumer.com/opensource/ucl/download/"
    regex(/href=.*?ucl[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfa42c0c242f02e72400b78d5c7c24967a997338e4e56e478b79aaa8bb5b1399"
  end

  depends_on "automake" => :build

  def install
    # Workaround to build with newer GCC
    ENV.append "CFLAGS", "-std=c90" if OS.linux?

    # Workaround for ancient ./configure file
    # Normally it would be cleaner to run "autoremake" to get a more modern one,
    # but the tarball doesn't seem to include all of the local m4 files that were used
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    # Workaround for ancient config.sub files not recognising aarch64 macos.
    # As above, autoremake would be nicer, but that does not work.
    %w[config.guess config.sub].each do |fn|
      cp "#{Formula["automake"].opt_prefix}/share/automake-#{Formula["automake"].version.major_minor}/#{fn}",
         "acconfig/#{fn}"
    end

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      // simplified version of
      // https://github.com/korczis/ucl/blob/HEAD/examples/simple.c
      #include <stdio.h>
      #include <ucl/ucl.h>
      #include <ucl/uclconf.h>
      #define IN_LEN      (128*1024L)
      #define OUT_LEN     (IN_LEN + IN_LEN / 8 + 256)
      int main(int argc, char *argv[]) {
          int r;
          ucl_byte *in, *out;
          ucl_uint in_len, out_len, new_len;

          if (ucl_init() != UCL_E_OK) { return 4; }
          in = (ucl_byte *) ucl_malloc(IN_LEN);
          out = (ucl_byte *) ucl_malloc(OUT_LEN);
          if (in == NULL || out == NULL) { return 3; }

          in_len = IN_LEN;
          ucl_memset(in,0,in_len);

          r = ucl_nrv2b_99_compress(in,in_len,out,&out_len,NULL,5,NULL,NULL);
          if (r != UCL_E_OK) { return 2; }
          if (out_len >= in_len) { return 0; }
          r = ucl_nrv2b_decompress_8(out,out_len,in,&new_len,NULL);
          if (r != UCL_E_OK && new_len == in_len) { return 1; }
          ucl_free(out);
          ucl_free(in);
          return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lucl", "-o", "test"
    system "./test"
  end
end
