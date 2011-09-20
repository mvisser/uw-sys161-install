#!/bin/sh

try_mkdir()
{
    if [ ! -d $1 ] ; then
        mkdir $1
    fi
}

PREFIX=$PWD
echo Prefix is ${PREFIX}

echo "=============================="
echo "Building utils..."
echo "=============================="
wget -c http://www.student.cs.uwaterloo.ca/~cs350/os161_repository/os161-binutils.tar.gz
tar -xzf os161-binutils.tar.gz
cd binutils*
./configure --nfp --disable-werror --target=mips-harvard-os161 --prefix=$PREFIX/sys161/tools
make -j6

# make sure they actually build
if [ $? ] ; then
    find . -name '*.info' -exec touch {} \;
    make -j6 || exit
fi

# install utils
make -j6 install
cd ..

# add stuff to path
echo "=============================="
echo "Adding path..."
echo "=============================="
try_mkdir -p $PREFIX/sys161/bin/
export PATH=$PREFIX/sys161/bin:$PREFIX/sys161/tools/bin:$PATH

# build GCC
echo "=============================="
echo "Building GCC..."
echo "=============================="
wget -c http://www.student.cs.uwaterloo.ca/~cs350/os161_repository/os161-gcc.tar.gz
tar -xzf os161-gcc.tar.gz
cd gcc*
./configure -nfp --disable-shared --disable-threads --disable-libmudflap --disable-libssp --target=mips-harvard-os161 --prefix=$PREFIX/sys161/tools 
make -j6 || exit
make -j6 install || exit
cd ..

# build GDB
echo "=============================="
echo "Building GDB..."
echo "=============================="
wget -c http://www.student.cs.uwaterloo.ca/~cs350/os161_repository/os161-gdb.tar.gz
tar -xzf os161-gdb.tar.gz 
cd gdb*
# NOTE: added -disable-werror because the build failed otherwise (Matthew Visser, Thu Sep 15)
./configure --disable-werror --target=mips-harvard-os161 --prefix=$PREFIX/sys161/tools 
make -j6 || exit
make -j6 install || exit
cd ..

# build the emulator
echo "=============================="
echo "Building the emulator..."
echo "=============================="
wget -c http://www.student.cs.uwaterloo.ca/~cs350/os161_repository/sys161.tar.gz
tar -xzf sys161.tar.gz 
cd sys161-*
./configure --prefix=$PREFIX/sys161 mipseb 
make || exit
make install || exit
cd ..

echo "=============================="
echo "Setting up links..."
echo "=============================="
pushd $PREFIX/sys161/tools/bin
for i in mips-*; do
    ln -s ../tools/bin/$i $PREFIX/sys161/bin/cs350-`echo $i | cut -d- -f4-`;
done
popd
pushd $PREFIX/sys161
ln -s share/examples/sys161/sys161.conf.sample sys161.conf
echo DONE\n Here is a listing of $PREFIX/sys161/bin:
ls $PREFIX/sys161/bin
popd


echo "=============================="
echo "Installing OS/161"
echo "=============================="
wget -c http://www.student.cs.uwaterloo.ca/~cs350/os161_repository/os161.tar.gz
try_mkdir cs350-os161
mv os161.tar.gz cs350-os161
pushd cs350-os161
tar -xzf os161.tar.gz
popd

echo "=============================="
echo "CLEANUP & MISC"
echo "=============================="

echo -n "Remove downloaded archives? [yN]"
read YN_DELETE
case  $YN_DELETE in
    [Yy])
        rm -i *.tar.gz ;;
esac

while [ "$YN_ADD_TO_RC" != "y"  -a "$YN_ADD_TO_RC" != "n" ] ; do
    echo -n "Do you want to add the path changes to your rc file? [yn] "
    read YN_ADD_TO_RC
    if [ $YN_ADD_TO_RC = "y" ] ; then
        case $SHELL in
            *bash)
                echo "export PATH=$PREFIX/sys161/bin:$PREFIX/sys161/tools/bin:\$PATH" >> ~/.bashrc
                ;;
            *zsh)
                echo "export PATH=$PREFIX/sys161/bin:$PREFIX/sys161/tools/bin:\$PATH" >> ~/.zshrc
                ;;
            *)
                echo "Your shell is not supported."
        esac
    fi
done

