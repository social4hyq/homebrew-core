class Starship < Formula
  desc "Cross-shell prompt for astronauts"
  homepage "https://starship.rs/"
  url "https://github.com/starship/starship/archive/refs/tags/v1.26.0.tar.gz"
  sha256 "8c95e8a6c596b29ac192104eae00dd991e8c8fd66083fd2b34d6b223a5803a59"
  license "ISC"
  revision 6
  head "https://github.com/starship/starship.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/starship-v1.26.0-r11"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aabb41c4cfea2acb4e714d6357bafa3554964bd81b9a3777e4ba7b110b1b6372"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "dbus"
    depends_on "zlib-ng-compat"
  end

  # guess_host_triple's errno 0.2.8 dep wrongly demands glibc's __xpg_strerror_r on musl/OHOS.
  resource "errno" do
    url "https://static.crates.io/crates/errno/errno-0.2.8.crate"
    sha256 "f639046355ee4f37944e44f60642c6f3a7efa3cf6b78c78a0d989a8ce6c396a1"
  end

  def install
    resource("errno").stage do
      inreplace "src/unix.rs", 'target_os = "linux", link_name = "__xpg_strerror_r"',
        'all(target_os = "linux", not(any(target_env = "musl", target_env = "ohos"))), link_name = "__xpg_strerror_r"'
      (buildpath/"vendor/errno").install Dir["*"]
    end
    open("Cargo.toml", "a") { |f| f.puts "[patch.crates-io]\nerrno = { path = \"vendor/errno\" }" }
    system "cargo", "update", "--package", "errno@0.2.8", "--precise", "0.2.8"

    # OHOS sandbox uid isn't in /etc/passwd, so whoami::username() only returns the
    # numeric uid ("100"). Fall back to the real OS-account name via NDK dlopen.
    inreplace "src/modules/username.rs",
      "pub fn module<'a>(context: &'a Context) -> Option<Module<'a>> {",
      <<~RUST + "pub fn module<'a>(context: &'a Context) -> Option<Module<'a>> {"
        fn ohos_account_username() -> Option<String> {
            unsafe extern "C" {
                fn dlopen(file: *const u8, flags: i32) -> *mut core::ffi::c_void;
                fn dlsym(handle: *mut core::ffi::c_void, name: *const u8) -> *mut core::ffi::c_void;
            }
            unsafe {
                let handle = dlopen(c"libos_account_ndk.so".as_ptr().cast(), 2 /* RTLD_NOW */);
                if handle.is_null() {
                    return None;
                }
                let sym = dlsym(handle, c"OH_OsAccount_GetName".as_ptr().cast());
                if sym.is_null() {
                    return None;
                }
                let get_name: extern "C" fn(*mut u8, usize) -> i32 = core::mem::transmute(sym);
                let mut buf = [0u8; 256];
                if get_name(buf.as_mut_ptr(), buf.len()) != 0 {
                    return None;
                }
                let end = buf.iter().position(|&b| b == 0).unwrap_or(buf.len());
                core::str::from_utf8(&buf[..end]).ok().filter(|s| !s.is_empty()).map(str::to_string)
            }
        }

      RUST

    inreplace "src/modules/username.rs",
      "whoami::username()",
      "ohos_account_username().map(Ok).unwrap_or_else(whoami::username)"

    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"starship", "completions")
  end

  test do
    ENV["STARSHIP_CONFIG"] = ""
    assert_equal "[1;32m❯[0m ", shell_output("#{bin}/starship module character")
  end
end
