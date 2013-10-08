require 'formula'

class ProtobufCxx11 < Formula
  homepage 'http://code.google.com/p/protobuf/'
  url 'http://protobuf.googlecode.com/files/protobuf-2.5.0.tar.bz2'
  sha1 '62c10dcdac4b69cc8c6bb19f73db40c264cb2726'

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
    ["protobuf-c++11.pc", "protobuf-c++11-lite.pc"].each do |f|
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
end

