require 'formula'

class ProtobufCxx11 < Formula
  homepage 'http://code.google.com/p/protobuf/'
  url 'http://protobuf.googlecode.com/files/protobuf-2.4.1.tar.bz2'
  sha1 'df5867e37a4b51fb69f53a8baf5b994938691d6d'

  option :universal

  fails_with :llvm do
    build 2334
  end

  def install
    # Don't build in debug mode. See:
    # https://github.com/mxcl/homebrew/issues/9279
    # http://code.google.com/p/protobuf/source/browse/trunk/configure.ac#61
    ENV.prepend 'CXXFLAGS', '-DNDEBUG'
    # Build with libc++ ...
    ENV.prepend 'CXXFLAGS', '-stdlib=libc++'
    ENV.prepend 'LDFLAGS', '-stdlib=libc++'

    ENV.universal_binary if build.universal?
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-zlib",
                          # Hide the library files, and include files from brew link
                          "--program-suffix=-cxx11",
                          "--includedir=#{libexec}/include/",
                          # LDFLAGS don't propogate correctly, so we link
                          # without -stdlib=libc++, which fails. No shared support.
                          "--enable-shared=no"
    system "make"
    system "make install"

    # Make sure we don't step on any toes of the protobuf Formula
    mv "#{lib}/pkgconfig/protobuf.pc", "#{lib}/pkgconfig/protobuf-c++11.pc"
    mv "#{lib}/pkgconfig/protobuf-lite.pc", "#{lib}/pkgconfig/protobuf-c++11-lite.pc"

    # Rename the libraries...
    mv "#{lib}/libprotoc.a", "#{lib}/libprotoc-cxx11.a"
    mv "#{lib}/libprotobuf.a", "#{lib}/libprotobuf-cxx11.a"
    mv "#{lib}/libprotobuf-lite.a", "#{lib}/libprotobuf-cxx11-lite.a"

    # Update the pkg-config files so that they contain the correct library name
    ["protobuf-c++11.pc", "protobuf-lite-c++11.pc"].each do |f|
        inreplace "#{lib}/pkgconfig/#{f}" do |s| 
            s.gsub! /-lprotobuf/, '-lprotobuf-cxx11'
        end
    end

    # Install editor support and examples
    doc.install %w( editors examples )
  end

  def caveats; <<-EOS.undent
    Editor support and examples have been installed to:
      #{doc}/protobuf
    
    This version is compiled with -stdlib=libc++, this means it is not
    compatible with older versions of the standard library. The libraries are
    renamed from their usual names, as have the pkg-config files. Unless you
    are absolutely sure that you need this Formula, you are most likely
    looking for the protobuf Formula. Install that one with brew install
    protobuf.
    EOS
  end

  def patches
      # Missing an include, patch is the same as on the FreeBSD ports tree:
      # http://lists.freebsd.org/pipermail/freebsd-ports-bugs/2012-March/229642.html
      DATA
    end
end

__END__
--- protobuf-2.4.1/src/google/protobuf/message.cc.orig	2012-11-25 18:58:20.000000000 -0700
+++ protobuf-2.4.1/src/google/protobuf/message.cc	2012-11-25 18:58:45.000000000 -0700
@@ -32,6 +32,7 @@
 //  Based on original Protocol Buffers design by
 //  Sanjay Ghemawat, Jeff Dean, and others.
 
+#include <iostream>
 #include <stack>
 #include <google/protobuf/stubs/hash.h>

