# StickerDownloader
StickerDownloader is downloading LINE Sticker from LINE Web page(Command Line Tool)

## install
git clone https://github.com/sho-ito-1027/StickerDownloader.git<br>
cd ./StickerDownloader<br>
$ make install

## run
$ stickerdl https://store.line.me/stickershop/product/3354/ja

## result 
Download sticker PNG file into ~/Downloads/$(web_page_title)/

--- 

## other install
git clone https://github.com/sho-ito-1027/StickerDownloader.git<br>
cd ./StickerDownloader<br>
$ swift build -c release

## other run
$ .build/release/StickerDownloader https://store.line.me/stickershop/product/3354/ja
