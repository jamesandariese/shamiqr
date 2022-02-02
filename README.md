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

Lowering the resolution and sharpening if there's a bunch of garbage in your 44 megapixel camera phone image or if it's just too big for zbarimg to understand:

```bash
convert IMG_4040.jpeg -resize 400x -unsharp 10x10 test.jpeg
unshamiqr test.jpeg output.txt
```

Try different values for resize until zbarimg gives the right number of qr codes.  As long as you've got the threshold number of shares, you should be good to go, however, so don't worry too much.

### `qrmost`

If you're having trouble finding a good size, try qrmost.  This will find the image with the most QR codes in it and optionally save it.

This operates via brute force checking so only use it if you need to or if you've got cycles to spare.

```bash
qrmost IMG_4040.jpeg best.jpeg
```

To just show which is best:
```bash
qrmost IMG_4040.jpeg
```

Or to specify that you only want to test between 477 and 2090 with a step size of 96 pixels:
```bash
qrmost -m 477 -x 2090 -s 96 IMG_4040.jpeg
```

Get help:

```bash
qrmost -h
```
