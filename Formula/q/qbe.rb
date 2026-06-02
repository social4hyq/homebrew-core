class Qbe < Formula
  desc "Compiler Backend"
  homepage "https://c9x.me/compile/"
  url "https://c9x.me/compile/release/qbe-1.3.tar.xz"
  sha256 "d587905d620dc5e1d2bfa7c2cc642b9b837aa89a3188c6e37b53d756cf66e320"
  license "MIT"
  head "git://c9x.me/qbe.git", branch: "master"

  livecheck do
    url "https://c9x.me/compile/releases.html"
    regex(/href=.*?qbe[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3625bb3aeca28f529f0a5576d0c6711959e3726e7580566ba80fd5d7071cdb9a"
  end

  def install
    system "make", "PREFIX=#{prefix}"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"main.ssa").write <<~EOS
      function w $add(w %a, w %b) {        # Define a function add
      @start
        %c =w add %a, %b                   # Adds the 2 arguments
        ret %c                             # Return the result
      }
      export function w $main() {          # Main function
      @start
        %r =w call $add(w 1, w 1)          # Call add(1, 1)
        call $printf(l $fmt, ..., w %r)    # Show the result
        ret 0
      }
      data $fmt = { b "One and one make %d!\n", b 0 }
    EOS

    system bin/"qbe", "-o", "out.s", "main.ssa"
    assert_path_exists testpath/"out.s"
  end
end
