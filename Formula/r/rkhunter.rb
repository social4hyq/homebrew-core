class Rkhunter < Formula
  desc "Rootkit hunter"
  homepage "https://rkhunter.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/rkhunter/rkhunter/1.4.6/rkhunter-1.4.6.tar.gz"
  sha256 "f750aa3e22f839b637a073647510d7aa3adf7496e21f3c875b7a368c71d37487"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d991ab665432093f1275857f44b653ebf2e0adf7ac3952688dd8a3e1a9617df4"
  end

  def install
    system "./installer.sh", "--layout", "custom", prefix, "--install"
  end

  test do
    system bin/"rkhunter", "--version"
  end
end
