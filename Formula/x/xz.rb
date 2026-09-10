class Xz < Formula
  desc "General-purpose data compression with high compression ratio"
  homepage "https://tukaani.org/xz/"
  url "https://github.com/tukaani-project/xz/releases/download/v5.8.4/xz-5.8.4.tar.gz"
  mirror "https://downloads.sourceforge.net/project/lzmautils/xz-5.8.4.tar.gz"
  mirror "http://downloads.sourceforge.net/project/lzmautils/xz-5.8.4.tar.gz"
  sha256 "0014c7886930454fe8bd4228665b51af55eeae560ea135c9c4cd33f55b2591d9"
  license all_of: [
    "0BSD",
    "GPL-2.0-or-later",
  ]
  revision 1
  version_scheme 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "44fbefc60347576b9f183e5dae4fe7e4bb9e702ca18b5b7ba54ef197fc553b3a"
  end

  deny_network_access! [:build, :postinstall]

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules", "--disable-nls"
    system "make", "check"
    system "make", "install"
  end

  test do
    path = testpath/"data.txt"
    original_contents = "." * 1000
    path.write original_contents

    # compress: data.txt -> data.txt.xz
    system bin/"xz", path
    refute_path_exists path

    # decompress: data.txt.xz -> data.txt
    system bin/"xz", "-d", "#{path}.xz"
    assert_equal original_contents, path.read

    # Check that http mirror works
    xz_tar = testpath/"xz.tar.gz"
    stable.mirrors.each do |mirror|
      next if mirror.start_with?("https")

      xz_tar.unlink if xz_tar.exist?

      # Set fake CA Cert to block any HTTPS redirects.
      system "curl", "--location", mirror, "--cacert", "/fake", "--output", xz_tar
      assert_equal stable.checksum.hexdigest, xz_tar.sha256
    end
  end
end
