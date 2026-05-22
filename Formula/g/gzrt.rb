class Gzrt < Formula
  desc "Gzip recovery toolkit"
  homepage "https://www.urbanophile.com/arenn/coding/gzrt/gzrt.html"
  url "https://www.urbanophile.com/arenn/coding/gzrt/gzrt-0.8.tar.gz"
  sha256 "b0b7dc53dadd8309ad9f43d6d6be7ac502c68ef854f1f9a15bd7f543e4571fee"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?gzrt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a7f8bc1d01728c41fbd48a0fea786a1b78a479803a9ac652489b687ade8c1fe1"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make"
    bin.install "gzrecover"
    man1.install "gzrecover.1"
  end

  test do
    filename = "data.txt"
    fixed_filename = "#{filename}.recovered"
    path = testpath/filename
    fixed_path = testpath/fixed_filename

    original_contents = "." * 1000
    path.write original_contents

    # Compress data into archive
    Utils::Gzip.compress path
    refute_path_exists path

    # Corrupt the archive to test the recovery process
    File.open("#{path}.gz", "r+b") do |file|
      file.seek(11)
      data = file.read(1).unpack1("C*")
      data = ~data
      file.write([data].pack("C*"))
    end

    # Verify that file corruption is detected and attempt to recover
    system bin/"gzrecover", "-v", "#{path}.gz"

    # Verify that recovered data is reasonably close - unlike lziprecover,
    # this process is not perfect, even for small errors
    assert_match original_contents, fixed_path.read
  end
end
