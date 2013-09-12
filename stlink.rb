require 'formula'

class Stlink < Formula
  homepage 'https://github.com/texane/stlink'
  # No available tarbals
  head 'https://github.com/texane/stlink.git', :using => :git
  sha1 ''

  depends_on 'pkg-config' => :build
  depends_on 'automake' => :build
  depends_on 'libusb'

  def install
    system "./autogen.sh"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make"
    system "make install"
  end

  def test
    system "st-util -h"
  end
end
