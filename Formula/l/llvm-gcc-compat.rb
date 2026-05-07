class LlvmGccCompat < Formula
  desc "Symlink OHOS LLVM tools to GCC-style names (gcc, ld, ar, etc.)"
  homepage "https://gitcode.com/Harmonybrew/homebrew-core"
  url "https://gitcode.com/Harmonybrew/homebrew-core.git", revision: "a8784ea451ad819d27a548411b8853fca6de3124"
  version "1.0.0"
  license "BSD-2-Clause"

  depends_on "ohos-sdk"

  def install
    ohos_bin = Formula["ohos-sdk"].opt_bin
    bin.mkpath

    tool_map = {
      "cc"        => "clang",
      "gcc"       => "clang",
      "c++"       => "clang++",
      "g++"       => "clang++",
      "cpp"       => "clang-cpp",
      "ld"        => "ld.lld",
      "addr2line" => "llvm-addr2line",
      "ar"        => "llvm-ar",
      "c++filt"   => "llvm-cxxfilt",
      "nm"        => "llvm-nm",
      "objcopy"   => "llvm-objcopy",
      "objdump"   => "llvm-objdump",
      "ranlib"    => "llvm-ranlib",
      "readelf"   => "llvm-readelf",
      "size"      => "llvm-size",
      "strip"     => "llvm-strip",
    }

    tool_map.each do |dest, src|
      source_path = ohos_bin/src
      if source_path.exist?
        ln_s source_path, bin/dest
      else
        opoo "Source tool #{src} not found in #{ohos_bin}, skipping #{dest}"
      end
    end
  end

  def caveats
    <<~EOS
      This formula creates symlinks to ohos-sdk.
      Ensure ohos-sdk is linked and functional.
    EOS
  end

  test do
    puts "Checking links in #{bin}:"
    system "ls", "-l", bin

    system "#{bin}/cc", "--version"
    system "#{bin}/ld", "--version"
  end
end
