mkdir -p build
cd build

root_address=https://github.com/alexjgriffith/update-lovejs/releases/download/115-beta1/

download_lovejs () {
    fname=$1
    echo "Downloading $fname"
    curl $root_address/$fname.zip > $fname.zip && unzip $fname.zip
    rm $fname.zip
    cd ../resources
    ln -s ../build/fname
}

download_lovejs "love115-compat-beta1";
download_lovejs "love115-release-beta1";
download_lovejs "love115-compat-single-beta1";
download_lovejs "love115-release-single-beta1";
