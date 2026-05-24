class Rhai < Formula
  desc "Embedded scripting language for Rust"
  homepage "https://rhai.rs/"
  url "https://github.com/rhaiscript/rhai/archive/refs/tags/v1.24.0.tar.gz"
  sha256 "2256dc43858be79516e8975948aca7fd66977ba9c445376c00b24b4a289c1cf1"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/rhaiscript/rhai.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ce5a41a7f19ab3fff3f91ab52d6e19b9d751a404b35a98212328b980decb0fa8"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"hello.rhai").write <<~RHAI
      print("Hello world!");
    RHAI

    (testpath/"fib.rhai").write <<~RHAI
      const TARGET = 28;
      const REPEAT = 5;
      const ANSWER = 317_811;

      fn fib(n) {
        if n < 2 {
            n
        } else {
          fib(n-1) + fib(n-2)
        }
      }

      let result;

      for n in 0..REPEAT {
          result = fib(TARGET);
      }

      print(`Fibonacci number #${TARGET} = ${result}`);

      if result != ANSWER {
          print(`The answer is WRONG! Should be ${ANSWER}!`);
      }
    RHAI

    assert_match "Hello world!", shell_output("#{bin}/rhai-run hello.rhai").chomp
    assert_match "Fibonacci number #28 = 317811", shell_output("#{bin}/rhai-run fib.rhai").chomp
  end
end
