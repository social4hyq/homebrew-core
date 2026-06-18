class Pax < Formula
  desc "Portable Archive Interchange archive tool"
  homepage "https://mbsd.evolvis.org/pax.htm"
  url "https://mbsd.evolvis.org/MirOS/dist/mir/cpio/paxmirabilis-20240817.tgz"
  sha256 "e955d5d3af97aede0a3f463a9a59b83e8d1083aaf142eb6f388c549a7d182e6b"
  license "MirOS"

  livecheck do
    url "https://mbsd.evolvis.org/MirOS/dist/mir/cpio"
    regex(/href=.*?paxmirabilis[._-]v?(\d+(?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "70eb7fd542d8b642fea4770c88c85972dce4815d0d1be699a7a33a2431780998"
  end

  keg_only :provided_by_macos

  patch do
    file "Patches/pax/musl-fts.patch"
  end

  def install
    mkdir "build" do
      system "sh", "../Build.sh", "-r", "-tpax"
      bin.install "pax"
    end
  end

  test do
    (testpath/"foo").write "test"
    system bin/"pax", "-f", testpath/"foo.pax", "-w", testpath/"foo"
    rm testpath/"foo"
    system bin/"pax", "-f", testpath/"foo.pax", "-r"
    assert_path_exists testpath/"foo"
  end
end
