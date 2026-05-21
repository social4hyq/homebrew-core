class Cdecl < Formula
  desc "Turn English phrases to C or C++ declarations"
  homepage "https://github.com/paul-j-lucas/cdecl"
  url "https://github.com/paul-j-lucas/cdecl/releases/download/cdecl-18.7.2/cdecl-18.7.2.tar.gz"
  sha256 "e91cc201c79456b923b45cfa779da62f5ca91824d11c545167ee7bb33a9fb810"
  license all_of: [
    "GPL-3.0-or-later",
    "LGPL-2.1-or-later", # gnulib
    :public_domain, # original cdecl
  ]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3c51aac40d3d9adb4314e035539dc4210d65c15b73b69b6963df292704908e3b"
  end

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "ncurses"

  on_linux do
    depends_on "readline"
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    assert_equal "declare a as pointer to integer",
                 shell_output("#{bin}/cdecl explain int *a").strip
  end
end
