class TodoTxt < Formula
  desc "Minimal, todo.txt-focused editor"
  homepage "http://todotxt.org/"
  url "https://github.com/todotxt/todo.txt-cli/releases/download/v2.13.0/todo.txt_cli-2.13.0.tar.gz"
  sha256 "d3b925434029aac212213c103fb6573a4f960c74dd467a3efac9bd9afe89d15f"
  license "GPL-3.0-only"
  head "https://github.com/todotxt/todo.txt-cli.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f75a4eb2402d63851a900bc14dff27120f612e1f2831cea4c4219655b91f4e37"
  end

  def install
    bin.install "todo.sh"
    prefix.install "todo.cfg" # Default config file
    bash_completion.install "todo_completion"
  end

  def caveats
    <<~EOS
      To configure, copy the default config to your HOME and edit it:
        cp #{prefix}/todo.cfg ~/.todo.cfg
    EOS
  end

  test do
    cp prefix/"todo.cfg", testpath/".todo.cfg"
    inreplace testpath/".todo.cfg", "export TODO_DIR=${HOME:-$USERPROFILE}", "export TODO_DIR=#{testpath}"
    system bin/"todo.sh", "add", "Hello World!"
    system bin/"todo.sh", "list"
  end
end
