class Ecoji < Formula
  desc "Encodes (and decodes) data as emojis"
  homepage "https://github.com/keith-turner/ecoji"
  url "https://github.com/keith-turner/ecoji/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "2f5de343c4e1032b328efe6a3a61d9ba6aae5ef668f99f0d06a16a9dda22e52e"
  license "Apache-2.0"
  head "https://github.com/keith-turner/ecoji.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cba18d81a73037e1af8584336ff61ccbed0fb292deedffc12cb6a84338c0cadf"
  end

  depends_on "go" => :build

  # Add missing go.sum file needed for module verification, upstream PR, https://github.com/keith-turner/ecoji/pull/39
  patch do
    url "https://github.com/keith-turner/ecoji/commit/ecc62c2cea558c776400b1da8161cef97848316c.patch?full_index=1"
    sha256 "b66530592062f64a03858633d85029271cc83a2b41bb84d31ce31667abcca71e"
  end

  def install
    cd "cmd/ecoji" do
      system "go", "build", *std_go_args(ldflags: "-s -w")
    end
  end

  test do
    text = "Base64 is so 1999"
    encoded_text = "🧏📩🧈🐇🧅📘🔯🚜💞😽♏🐊🎱🤾☕"
    assert_equal encoded_text, pipe_output("#{bin}/ecoji -e", text).chomp
    assert_equal text, pipe_output("#{bin}/ecoji -d", encoded_text).chomp
  end
end
