class Planus < Formula
  desc "Alternative compiler for flatbuffers,"
  homepage "https://github.com/planus-org/planus"
  url "https://github.com/planus-org/planus/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "eb4f65fced93a1c04f14a17ff5978f930cf68e2026a0f24d13a214d045a920ed"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/planus-org/planus.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5a48320b9a328de3710cf411108474b63d398fc423a0c456fc71011993560e1d"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/planus-cli")

    generate_completions_from_executable(bin/"planus", "generate-completions")
  end

  test do
    test_fbs = testpath/"test.fbs"
    test_fbs.write <<~EOS
      // example IDL file

      namespace MyGame.Sample;

      enum Color:byte { Red = 0, Green, Blue = 2 }

      union Any { Monster }  // add more elements..

        struct Vec3 {
          x:float;
          y:float;
          z:float;
        }

        table Monster {
          pos:Vec3;
          mana:short = 150;
          hp:short = 100;
          name:string;
          friendly:bool = false (deprecated);
          inventory:[ubyte];
          color:Color = Blue;
        }

      root_type Monster;

    EOS

    system bin/"planus", "format", test_fbs
    system bin/"planus", "check", test_fbs
  end
end
