class T1lib < Formula
  desc "C library to generate/rasterize bitmaps from Type 1 fonts"
  homepage "https://www.t1lib.org/"
  url "https://www.ibiblio.org/pub/linux/libs/graphics/t1lib-5.1.2.tar.gz"
  mirror "https://fossies.org/linux/misc/old/t1lib-5.1.2.tar.gz"
  sha256 "821328b5054f7890a0d0cd2f52825270705df3641dbd476d58d17e56ed957b59"
  license "GPL-2.0-only"

  livecheck do
    url "https://www.ibiblio.org/pub/Linux/libs/graphics/"
    regex(/href=.*?t1lib[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "04c8e1ce2130801cbc57a2a23c5f07ec9b717215eec7b36082b81767d20de702"
  end

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "without_doc"
    system "make", "install"
    share.install "Fonts" => "fonts"
  end

  test do
    # T1_SetString seems to fail on macOS with "(E) T1_SetString(): t1_abort: Reason: unable to fix subpath break?"
    # https://github.com/Homebrew/homebrew-core/pull/194149#issuecomment-2412940237
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include <t1lib.h>

      int main( void)
      {
        int i;
        T1_SetBitmapPad(16);

        if ((T1_InitLib(NO_LOGFILE)==NULL)){
          fprintf(stderr, "Initialization of t1lib failed\\n");
          return EXIT_FAILURE;
        }

        for( i=0; i<T1_GetNoFonts(); i++){
          printf("FontID=%d, Font=%s\\n", i, T1_GetFontFilePath(i));
          printf("FontID=%d, Metrics=%s\\n", i, T1_GetAfmFilePath(i));
          // T1_DumpGlyph(T1_SetString( i, "Test", 0, 0, T1_KERNING, 25.0, NULL));
        }

        T1_CloseLib();
        return EXIT_SUCCESS;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lt1", "-o", "test"

    testpath.install_symlink Formula["t1lib"].opt_share/"fonts/afm/bchr.afm"
    testpath.install_symlink Formula["t1lib"].opt_share/"fonts/type1/bchr.pfb"
    (testpath/"FontDataBase").write "1\nbchr.afm\n"
    (testpath/"t1lib.config").write <<~EOS
      FONTDATABASE=./FontDataBase
      ENCODING=.
      AFM=.
      TYPE1=.
    EOS

    expected_output = <<~EOS
      FontID=0, Font=./bchr.pfb
      FontID=0, Metrics=./bchr.afm
    EOS

    with_env(T1LIB_CONFIG: testpath/"t1lib.config") do
      assert_equal expected_output, shell_output("./test")
    end
  end
end
