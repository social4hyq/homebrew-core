class Jo < Formula
  desc "JSON output from a shell"
  homepage "https://github.com/jpmens/jo"
  url "https://github.com/jpmens/jo/releases/download/1.9/jo-1.9.tar.gz"
  sha256 "0195cd6f2a41103c21544e99cd9517b0bce2d2dc8cde31a34867977f8a19c79f"
  license all_of: ["GPL-2.0-or-later", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21835ea4e35e2a7d7fa62c20132a34a7e5471ece45b294151a9c47cc8cfeec3c"
  end

  head do
    url "https://github.com/jpmens/jo.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
    bash_completion.install bash_completion/"jo.bash" => "jo"
  end

  test do
    assert_equal %Q({"success":true,"result":"pass"}\n), shell_output("#{bin}/jo success=true result=pass")
  end
end
