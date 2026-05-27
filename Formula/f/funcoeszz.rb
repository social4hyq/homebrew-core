class Funcoeszz < Formula
  desc "Dozens of command-line mini-applications (Portuguese)"
  homepage "https://funcoeszz.net/"
  url "https://funcoeszz.net/download/funcoeszz-21.1.sh"
  sha256 "630017119208b576387e18db8734dbda9d9e7750c742f9c3ffec7232b7636856"
  license "GPL-2.0-only"

  livecheck do
    url "https://funcoeszz.net/download/"
    regex(/href=.*?funcoeszz[._-]v?(\d+(?:\.\d+)+)\.sh/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0dde86e7e59b660dc449a9bff68efe929adbba046c3a35a0b15adfe609440041"
  end

  uses_from_macos "bc-gh" => :test

  on_macos do
    depends_on "bash"
  end

  def install
    bin.install "funcoeszz-#{version}.sh" => "funcoeszz"
  end

  def caveats
    <<~EOS
      To use this software add to your profile:
        export ZZPATH="#{opt_bin}/funcoeszz"
        source "$ZZPATH"

      Usage of a newer Bash than the macOS default is required.
    EOS
  end

  test do
    assert_equal "15", shell_output("#{bin}/funcoeszz zzcalcula 10+5").chomp
  end
end
