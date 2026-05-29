class Lzsa < Formula
  desc "Lossless packer that is optimized for fast decompression on 8-bit micros"
  homepage "https://github.com/emmanuel-marty/lzsa"
  url "https://github.com/emmanuel-marty/lzsa/archive/refs/tags/1.4.1.tar.gz"
  sha256 "c65ca1e6a43696f4ca5edc2c98229fba1044806bd21bc2a8ce4b867dc9cfc45c"
  license all_of: ["Zlib", "CC0-1.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2b448c52436d3b027d6dac75ebaf141099c5fb12326f25bd511473c15996920d"
  end

  def install
    system "make"
    bin.install "lzsa"
  end

  test do
    File.write("test.txt", "This is a test file for LZSA.\n")
    system bin/"lzsa", "test.txt", "test.lz"
    assert_path_exists testpath/"test.lz"
  end
end
