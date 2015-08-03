#! /bin/bash
# Author: Thomas KalhÃ¸j Clemensen (@ThomasCle)
# Company: iDeal Development
# 
# How to use:
# ./ThomasCleFat.sh <Entire path to Products folder> <Name of library-file> <Name of output file>
#
# Example:
# ./ThomasCleFat.sh /Users/thomas/Library/Developer/Xcode/DerivedData/IDAREngineLibrary-drhdoduifoxcelfnkvtqcwkzkfhp/Build/Products libIDAREngineLibrary.a libIDAREngine.a

echo "ThomasCle welcomes you!"
echo "Stating script with parameters:"
echo "Library name: $2"

cd $1
if test -d FAT; then 
	echo ":-)"; 
else
	echo "Creating folder FAT";
	mkdir FAT;
fi 
lipo -create Debug-iphonesimulator/$2 Debug-iphoneos/$2 -output FAT/$3

if test -f FAT/$3; then 
	echo "Successfully performed a FAT-combine on FAT/$3";
else
	echo "Failed to create file! :-(";
fi