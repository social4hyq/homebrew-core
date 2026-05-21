class Hilite < Formula
  desc "CLI tool that runs a command and highlights STDERR output"
  homepage "https://sourceforge.net/projects/hilite/"
  url "https://downloads.sourceforge.net/project/hilite/hilite/1.5/hilite.c"
  sha256 "e15bdff2605e8d23832d6828a62194ca26dedab691c9d75df2877468c2f6aaeb"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b9204e9610fd44a2476e3e94bd0b112e03ce069eaafe3eed16b5cccd0c9a66fc"
  end

  def install
    system ENV.cc, "hilite.c", "-o", "hilite", *ENV.cflags.to_s.split
    bin.install "hilite"
  end

  test do
    system bin/"hilite", "bash", "-c", "echo 'stderr in red' >&2"
  end
end
