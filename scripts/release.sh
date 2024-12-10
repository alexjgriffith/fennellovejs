LOVE_VERSION=115
LOVEJS_VERSION=beta1
mkdir -p release/
rm release/*
for file in $(ls build);
do
    echo -e "building love$LOVE_VERSION-$file-$LOVEJS_VERSION.zip"
    rm build/$file/love/love*.zip
    ls build/$file/love/love* | grep -v ".zip" | env TZ=UTC zip -j -r -q -9 -X build/$file/love/love$LOVE_VERSION-$file-$LOVEJS_VERSION.zip -@
    cp build/$file/love/love$LOVE_VERSION-$file-$LOVEJS_VERSION.zip release/
done
