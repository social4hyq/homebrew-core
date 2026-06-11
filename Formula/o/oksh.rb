class Oksh < Formula
  desc "Portable OpenBSD ksh, based on the public domain Korn shell (pdksh)"
  homepage "https://github.com/ibara/oksh"
  url "https://github.com/ibara/oksh/releases/download/oksh-7.9/oksh-7.9.tar.gz"
  sha256 "51b2d92515950c959dbf24f6fc33336db8c0526c2a50fee4ca598a18a6114a49"
  license all_of: [:public_domain, "BSD-3-Clause", "ISC"]
  head "https://github.com/ibara/oksh.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2881c8beb3d5bb611bba9abe3d8fbf050b70d44e7cb4f7e5537841b0c285e51a"
  end

  uses_from_macos "ncurses"

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make"
    system "make", "install"
  end

  test do
    assert_equal "hello", shell_output("#{bin}/oksh -c \"echo -n hello\"")
  end
end
