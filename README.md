# `shamiqr`

Shamir shares in QR codes!

## Prerequisites

This requires ImageMagick, qrencode, libgfshare utils, and zbarimg.  Example also requires uuid command.

### MacOS with brew

```bash
brew install libgfshare qrencode coreutils imagemagick zbar
```

## Installing

There is a script which will copy the [un]shamiqr scripts to $HOME/bin.

This is all it does so feel free to do it yourself if you prefer.

```bash
./install.sh
```

## Encoding

Create a png by interactively typing a password:

```bash
shamiqr output.png
```

Create a jpeg from a random UUID

```bash
uuid -v4 | shamiqr output.jpeg
```

## Decoding

Decoding a secret from an image with a bunch of QR codes in it (must only by shamiqr codes):

```bash
unshamiqr IMG_4040.jpg output.txt
```

Lowering the resolution if there's a bunch of garbage in your image:

```bash
convert IMG_4040.jpeg -resize 400x -unsharp 0x1 test.jpeg
unshamiqr test.jpeg output.txt
```
