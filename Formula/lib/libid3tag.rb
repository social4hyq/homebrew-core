class Libid3tag < Formula
  desc "ID3 tag manipulation library"
  homepage "https://codeberg.org/tenacityteam/libid3tag"
  url "https://codeberg.org/tenacityteam/libid3tag/releases/download/0.16.4/id3tag-0.16.4-source.tar.gz"
  sha256 "8b6bc96016f6ab3a52b753349ed442e15181de9db1df01884f829e3d4f3d1e78"
  license "GPL-2.0-or-later"
  compatibility_version 1
  head "https://codeberg.org/tenacityteam/libid3tag.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "875089aa1e15097953a1970fba63775f182c31dc59b542786927d8752775f96e"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :test

  uses_from_macos "gperf" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <id3tag.h>

      int main() {
        struct id3_file *fp = id3_file_open("#{test_fixtures("test.mp3")}", ID3_FILE_MODE_READONLY);
        struct id3_tag *tag = id3_file_tag(fp);
        struct id3_frame *frame = id3_tag_findframe(tag, ID3_FRAME_TITLE, 0);
        id3_file_close(fp);

        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs id3tag").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
