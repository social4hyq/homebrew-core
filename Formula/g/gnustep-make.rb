class GnustepMake < Formula
  desc "Basic GNUstep Makefiles"
  homepage "https://www.gnustep.org/"
  url "https://github.com/gnustep/tools-make/releases/download/make-2_9_3/gnustep-make-2.9.3.tar.gz"
  sha256 "93ca320b706279ebca53760da89d4c3f2bbc547f4723967140a34346d9f04c24"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    regex(/^make[._-]v?(\d+(?:[._]\d+)+)$/i)
    strategy :github_latest do |json, regex|
      json["tag_name"]&.scan(regex)&.map { |match| match[0].tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1927466dad9e2086c574d3bbf0afd49c5213e0478413759a9096b6989f78ab5a"
  end

  def install
    system "./configure", *std_configure_args,
                          "--with-config-file=#{prefix}/etc/GNUstep.conf",
                          "--enable-native-objc-exceptions"
    system "make", "install", "tooldir=#{libexec}"
  end

  test do
    assert_match shell_output("#{libexec}/gnustep-config --variable=CC").chomp, ENV.cc
  end
end
