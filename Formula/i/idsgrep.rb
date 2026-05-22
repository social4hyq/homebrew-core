class Idsgrep < Formula
  desc "Grep for Extended Ideographic Description Sequences"
  homepage "https://tsukurimashou.org/idsgrep.php.en"
  url "https://tsukurimashou.org/files/idsgrep-0.6.tar.gz"
  sha256 "2c07029bab12d9ceefddf447ce4213535b68d020b093a593190c2afa8a577c7c"
  license "GPL-3.0-only"

  livecheck do
    url :homepage
    regex(/href=.*idsgrep[._-]v?(\d+(?:\.\d+)+)\.t*/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "896cf12377790d7394f7f16172eba49c7c371f5532120e8fee82baff5e118ba8"
  end

  depends_on "cmake" => :build

  def install
    system "./configure", "--disable-silent-rules",
                          "--without-pcre",
                          *std_configure_args.reject { |arg| arg["--libdir"] }
    system "make", "install"
    pkgshare.install "chise.eids"
  end

  test do
    expected = <<~EOS
      【䲤】⿰⻥<酒>⿰氵酉
      【酒】⿰氵酉
      【鿐】⿰魚<酒>⿰氵酉
      【𤄍】⿰<酒>⿰氵酉<留>⿱<CDP-8C69>⿰<CDP-88EE>;刀田
      【𦵩】⿱艹<酒>⿰氵酉
      【𫇓】⿳⿴𦥑<林>⿰木木冖<酒>⿰氵酉
      【𬜂】⿱⿴𦥑<林>⿰木木<酒>⿰氵酉
      【𭊼】⿱<酒>⿰氵酉<吒>⿰口<乇>⿱丿七
      【𭳒】⿰<酒>⿰氵酉<或>⿹戈<CDP-8BE2>⿱口一
    EOS
    assert_equal expected, shell_output("#{bin}/idsgrep -dk '...酒' #{pkgshare}/chise.eids")
  end
end
