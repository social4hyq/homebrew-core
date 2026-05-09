class Daemonize < Formula
  desc "Run a command as a UNIX daemon"
  homepage "https://software.clapper.org/daemonize/"
  url "https://github.com/bmc/daemonize/archive/refs/tags/release-1.7.8.tar.gz"
  sha256 "20c4fc9925371d1ddf1b57947f8fb93e2036eb9ccc3b43a1e3678ea8471c4c60"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dd7af26960038cb2a67b5e83c4dd69ca8e23ff9c90b77344c1d6074359e88061"
  end

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    dummy_script_file = testpath/"script.sh"
    output_file = testpath/"outputfile.txt"
    pid_file = testpath/"pidfile.txt"
    dummy_script_file.write <<~SH
      #!/bin/sh
      echo "#{version}" >> "#{output_file}"
    SH
    chmod 0700, dummy_script_file
    system sbin/"daemonize", "-p", pid_file, dummy_script_file
    assert_path_exists pid_file, "The file containing the PID of the child process was not created."
    sleep(4) # sleep while waiting for the dummy script to finish
    assert_path_exists output_file, "The file which should have been created by the child process doesn't exist."
    assert_match version.to_s, output_file.read
  end
end
