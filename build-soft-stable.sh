#!/bin/bash

export CFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
export CXXFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"

LIBXISF_COMMIT="v0.2.13"
INDI_COMMIT="v2.1.3"
INDI_3RD_COMMIT="v2.1.3"
STELLAR_COMMIT="157092d6f843fb987818bd61f0b14b440eca3146"
KSTARS_COMMIT="origin/stable-3.7.6"
PHD2_COMMIT="v2.6.13"

# you can set custom BUILD_DIR
BUILD_DIR=${BUILD_DIR:-$HOME}
ROOTDIR="$BUILD_DIR/astro-soft-stable"

JOBS=$(grep -c ^processor /proc/cpuinfo)

# 64 bit systems need more memory for compilation
if [ $(getconf LONG_BIT) -eq 64 ] && [ $(grep MemTotal < /proc/meminfo | cut -f 2 -d ':' | sed s/kB//) -lt 5000000 ]
then
	echo "Low memory limiting to JOBS=2"
	JOBS=2
fi

[ ! -d "$ROOTDIR" ] && mkdir -p "$ROOTDIR"
cd "$ROOTDIR"

echo "Build dir = $BUILD_DIR"
echo "Root dir  = $ROOTDIR"
echo "Jobs      = $JOBS"

echo "Start build at:        `date`" >> $BUILD_DIR/build_log.txt

# delete all previously installed files
[ -f build-libXISF/install_manifest.txt ] && echo "Deleting libXISF"; cat build-libXISF/install_manifest.txt | sudo xargs rm -f
[ -f build-indi/install_manifest.txt ] && echo "Deleting INDI"; cat build-indi/install_manifest.txt | sudo xargs rm -f
[ -f build-indi-lib/install_manifest.txt ] && cat build-indi-lib/install_manifest.txt | sudo xargs rm -f
[ -f build-indi-3rdparty/install_manifest.txt ] && echo "Deleting INDI 3rdparty"; cat build-indi-3rdparty/install_manifest.txt | sudo xargs rm -f
[ -f build-stellarsolver/install_manifest.txt ] && echo "Deleting stellarsolver"; cat build-stellarsolver/install_manifest.txt | sudo xargs rm -f
[ -f build-kstars/install_manifest.txt ] && echo "Deleting KStars"; cat build-kstars/install_manifest.txt | sudo xargs rm -f

echo "building libXISF:      `date`" >> $BUILD_DIR/build_log.txt
[ ! -d "libXISF" ] && { git clone https://gitea.nouspiro.space/nou/libXISF.git || { echo "Failed to clone LibXISF"; exit 1; } }
cd libXISF
git fetch origin
git switch -d --discard-changes $LIBXISF_COMMIT
[ ! -d ../build-libXISF ] && { cmake -B ../build-libXISF ../libXISF -DCMAKE_BUILD_TYPE=Release || { echo "LibXISF configuration failed"; exit 1; } }
cd ../build-libXISF
make -j $JOBS || { echo "LibXISF compilation failed"; exit 1; }
sudo make install || { echo "LibXISF installation failed"; exit 1; }

echo "building INDI:         `date`" >> $BUILD_DIR/build_log.txt
cd "$ROOTDIR"
[ ! -d "indi" ] && { git clone https://github.com/indilib/indi.git || { echo "Failed to clone indi"; exit 1; } }
cd indi
git fetch origin
git switch -d --discard-changes $INDI_COMMIT
[ ! -d ../build-indi ] && { cmake -B ../build-indi ../indi -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release || { echo "INDI configuration failed"; exit 1; } }
cd ../build-indi
make -j $JOBS || { echo "INDI compilation failed"; exit 1; }
sudo make install || { echo "INDI installation failed"; exit 1; }

echo "building INDI-LIB      `date`" >> $BUILD_DIR/build_log.txt
cd "$ROOTDIR"
[ ! -d "indi-3rdparty" ] && { git clone https://github.com/indilib/indi-3rdparty.git || { echo "Failed to clone indi 3rdparty"; exit 1; } }
cd indi-3rdparty
git fetch origin
git switch -d --discard-changes $INDI_3RD_COMMIT
[ ! -d ../build-indi-lib ] && { cmake -B ../build-indi-lib ../indi-3rdparty -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_LIBS=1 -DCMAKE_BUILD_TYPE=Release || { echo "INDI lib configuration failed"; exit 1; } }
cd ../build-indi-lib
make -j $JOBS || { echo "INDI lib compilation failed"; exit 1; }
sudo make install || { echo "INDI lib installation failed"; exit 1; }

echo "building INDI-3RDPARTY `date`" >> $BUILD_DIR/build_log.txt
[ ! -d ../build-indi-3rdparty ] && { cmake -B ../build-indi-3rdparty ../indi-3rdparty -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release || { echo "INDI lib configuration failed"; exit 1; } }
cd ../build-indi-3rdparty
make -j $JOBS || { echo "INDI 3rd-party compilation failed"; exit 1; }
sudo make install || { echo "INDI lib installation failed"; exit 1; }

echo "building STELLARSOLVER `date`" >> $BUILD_DIR/build_log.txt
cd "$ROOTDIR"
[ ! -d "stellarsolver" ] && { git clone https://github.com/rlancaste/stellarsolver.git || { echo "Failed to clone stellarsolver"; exit 1; } }
cd stellarsolver
git fetch origin
git switch -d --discard-changes $STELLAR_COMMIT
[ ! -d ../build-stellarsolver ] && { cmake -B ../build-stellarsolver ../stellarsolver -DCMAKE_BUILD_TYPE=Release || { echo "Stellarsolfer configuration failed"; exit 1; } }
cd ../build-stellarsolver
make -j $JOBS || { echo "Stellarsolver compilation failed"; exit 1; }
sudo make install || { echo "Stellarsolver installation failed"; exit 1; }

echo "building KSTARS        `date`" >> $BUILD_DIR/build_log.txt
cd "$ROOTDIR"
[ ! -d "kstars" ] && { git clone https://invent.kde.org/education/kstars.git || { echo "Failed to clone KStars"; exit 1; } }
cd kstars
git fetch origin
git switch -d --discard-changes $KSTARS_COMMIT
[ ! -d ../build-kstars ] && { cmake -B ../build-kstars -DBUILD_TESTING=Off ../kstars -DCMAKE_BUILD_TYPE=Release || { echo "KStars configuration failed"; exit 1; } }
cd ../build-kstars
make -j $JOBS || { echo "KStars compilation failed"; exit 1; }
sudo make install || { echo "KStars installation failed"; exit 1; }

sudo ldconfig

[ "$1" != "phd2" ] && exit

echo "building PHD2          `date`" >> $BUILD_DIR/build_log.txt
cd "$ROOTDIR"
[ ! -d "phd2" ] && { git clone https://github.com/OpenPHDGuiding/phd2.git || { echo "Failed to clone PHD2"; exit 1; } }
cd phd2
git fetch origin
git switch -d --discard-changes $PHD2_COMMIT
[ ! -d ../build-phd2 ] && { cmake -B ../build-phd2 ../phd2 -DCMAKE_BUILD_TYPE=Release || { echo "PHD2 configuration failed"; exit 1; } }
cd ../build-phd2
make -j $JOBS || { echo "PHD2 compilation failed"; exit 1; }
sudo make install || { echo "PHD2 installation failed"; exit 1; }

echo "Finished build at:     `date`" >> $BUILD_DIR/build_log.txt
