class Starship < Formula
  desc "Cross-shell prompt for astronauts"
  homepage "https://starship.rs/"
  url "https://github.com/starship/starship/archive/refs/tags/v1.26.0.tar.gz"
  sha256 "8c95e8a6c596b29ac192104eae00dd991e8c8fd66083fd2b34d6b223a5803a59"
  license "ISC"
  revision 7
  head "https://github.com/starship/starship.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/starship-v1.26.0-r15"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7a0343e5c801e7b8ed4927eb48bcfdac3e7126824894c0fcae1127e5d40bf044"
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

    patch do
      file "Patches/starship/errno-strerror-r-ohos.patch"
    end
  end

  # OHOS sandbox uid isn't in /etc/passwd, so whoami::username() only returns the
  # numeric uid ("100"). Fall back to the real OS-account name via NDK dlopen.
  patch do
    file "Patches/starship/username-ohos-account-fallback.patch"
  end

  # New-file patch: OHOS shell init glue shipped as a keg script by install().
  # The OS zsh (/usr/bin/zsh, a 5.9 CI build) lacks zsh/mathfunc and has no brew
  # function dirs in its compiled-in fpath; the device also has no /etc/localtime.
  patch do
    file "Patches/starship/ohos-init.zsh.patch"
  end

  def install
    resource("errno").stage do
      (buildpath/"vendor/errno").install Dir["*"]
    end
    open("Cargo.toml", "a") { |f| f.puts "[patch.crates-io]\nerrno = { path = \"vendor/errno\" }" }
    system "cargo", "update", "--package", "errno@0.2.8", "--precise", "0.2.8"

    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"starship", "completions")

    # Ship the OHOS shell-init glue (created by ohos-init.zsh.patch) as a keg
    # script; see caveats for the one-line .zshrc hookup.
    pkgshare.mkpath
    (pkgshare/"ohos-init.zsh").install buildpath/"ohos-init.zsh"
  end

  def caveats
    <<~CAVEATS
      Set up starship on OHOS (add this line to ~/.zshrc):

        [ -f "$(brew --prefix)/opt/starship/share/starship/ohos-init.zsh" ] && source "$(brew --prefix)/opt/starship/share/starship/ohos-init.zsh"

      The OHOS glue (timezone fallback, fpath, compinit, mathfunc fallback)
      lives in the keg and upgrades with `brew upgrade starship`.
    CAVEATS
  end

  test do
    assert_path_exists pkgshare/"ohos-init.zsh"
    ENV["STARSHIP_CONFIG"] = ""
    assert_equal "[1;32m❯[0m ", shell_output("#{bin}/starship module character")
  end
end
