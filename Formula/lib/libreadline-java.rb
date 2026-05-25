class LibreadlineJava < Formula
  desc "Port of GNU readline for Java"
  homepage "https://github.com/aclemons/java-readline"
  url "https://github.com/aclemons/java-readline/releases/download/v0.8.4/libreadline-java-0.8.4-src.tar.gz"
  sha256 "8767f1e5ba01c5bece9401871b318e9a28607d199a14def7a7bcb495059c2958"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    regex(/^[vR]?_?(\d+(?:[._-]\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c8991e35e1964868150abb060e0125c8e8fece3ef50e6b49b75dc748b041b5b"
  end

  depends_on "openjdk"
  depends_on "readline"

  def install
    ENV["JAVA_HOME"] = java_home = Language::Java.java_home

    # Current Oracle JDKs put the jni.h and jni_md.h in a different place than the
    # original Apple/Sun JDK used to.
    ENV["JAVAINCLUDE"] = "#{java_home}/include"
    ENV["JAVANATINC"]  = "#{java_home}/include/#{OS.kernel_name.downcase}"

    # Take care of some hard-coded paths,
    # adjust postfix of jni libraries,
    # adjust gnu install parameters to bsd install
    inreplace "Makefile" do |s|
      s.change_make_var! "PREFIX", prefix
      s.change_make_var! "JAVAC_VERSION", Formula["openjdk"].version.to_s
      s.change_make_var! "JAVALIBDIR", "$(PREFIX)/share/libreadline-java"
      s.change_make_var! "JAVAINCLUDE", ENV["JAVAINCLUDE"]
      s.change_make_var! "JAVANATINC", ENV["JAVANATINC"]
      s.gsub! "*.so", "*.jnilib" if OS.mac?
      s.gsub! "install -D", "install -c"
    end

    # Take care of some hard-coded paths,
    # adjust CC variable,
    # adjust postfix of jni libraries
    inreplace "src/native/Makefile" do |s|
      readline = Formula["readline"]
      s.change_make_var! "INCLUDES", "-I $(JAVAINCLUDE) -I $(JAVANATINC) -I #{readline.opt_include}"
      s.change_make_var! "LIBPATH", "-L#{readline.opt_lib}"
      s.change_make_var! "CC", "cc"
      if OS.mac?
        s.change_make_var! "LIB_EXT", "jnilib"
        s.change_make_var! "LD_FLAGS", "-install_name #{HOMEBREW_PREFIX}/lib/$(LIB_PRE)$(TG).$(LIB_EXT) -dynamiclib"
      end
    end

    pkgshare.mkpath

    system "make", "jar"
    system "make", "build-native"
    system "make", "install"

    doc.install "api"
  end

  def caveats
    <<~EOS
      You may need to set JAVA_HOME:
        export JAVA_HOME="$(/usr/libexec/java_home)"
    EOS
  end

  # Testing libreadline-java (can we execute and exit libreadline without exceptions?)
  test do
    java_path = Formula["openjdk"].opt_bin/"java"
    assert(/Exception/ !~ pipe_output(
      "#{java_path} -Djava.library.path=#{lib} -cp #{pkgshare}/libreadline-java.jar test.ReadlineTest",
      "exit",
    ))
  end
end
