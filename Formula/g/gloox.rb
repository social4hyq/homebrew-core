class Gloox < Formula
  desc "C++ Jabber/XMPP library that handles the low-level protocol"
  homepage "https://camaya.net/gloox/"
  url "https://camaya.net/download/gloox-1.0.28.tar.bz2"
  sha256 "591bd12c249ede0b50a1ef6b99ac0de8ef9c1ba4fd2e186f97a740215cc5966c"
  license "GPL-3.0-only" => { with: "openvpn-openssl-exception" }

  livecheck do
    url :homepage
    regex(/Latest stable version.*?href=.*?gloox[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b8b6de3ba58260a9e395a59850c3646197fe96095bfac6e69afb8fa54cb28e77"
  end

  depends_on "pkgconf" => :build
  depends_on "libidn"
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Fix build issue with `{ 0 }`, build patch sent to upstream author
  patch :DATA

  def install
    system "./configure", "--disable-silent-rules",
                          "--with-zlib",
                          "--with-openssl=#{Formula["openssl@3"].opt_prefix}",
                          "--without-tests",
                          "--without-examples",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"gloox-config", "--cflags", "--libs", "--version"
  end
end

__END__
diff --git a/src/tlsopensslclient.cpp b/src/tlsopensslclient.cpp
index ca18096..52322b1 100644
--- a/src/tlsopensslclient.cpp
+++ b/src/tlsopensslclient.cpp
@@ -51,7 +51,11 @@ namespace gloox
     {
       unsigned char buf[32];
       const char* const label = "EXPORTER-Channel-Binding";
-      SSL_export_keying_material( m_ssl, buf, 32, label, strlen( label ), { 0 }, 1, 0 );
+
+      unsigned char context[] = {0}; // Context initialized to zero
+      size_t context_len = sizeof(context); // Length of the context
+
+      SSL_export_keying_material(m_ssl, buf, 32, label, strlen(label), context, context_len, 0);
       return std::string( reinterpret_cast<char* const>( buf ), 32 );
     }
     else
