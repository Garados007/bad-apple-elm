# Bad Apple in Elm

This is a website that fetches every frame of [Bad Apple](https://www.youtube.com/watch?v=9lNZ_Rnr7Jc)
as single Bitmap (BMP) files and read every pixel in binary.

To show the frames this website uses a matrix of div containers and set the background color of each
cell.

For convenience it adds the audio file with HTML5 (no fancy magic, I am sorry).

In my tests with my old laptop this can display the whole video with the full 24 frames per seconds
with ~0,1% frame drops. 

## How to Run

You need to to have the following programms installed:

- `youtube-dl`
- `ffmpeg`
- `imagemagick`
- `elm`
- any webserver to deliver the resulting content (e.g. `nginx`, `apache`)

After that you download the video from YouTube:

```bash
$ youtube-dl -o bad-apple.mp4 https://www.youtube.com/watch?v=9lNZ_Rnr7Jc
```

> You can use another video but you have to change the maximum number of frames later.

Now we need `ffmpeg` and `imagemagick` to get our frames as bitmaps:

```bash
$ mkdir frames
$ ffmpeg -i bad-apple.mp4 frames/frame-%d.png
$ for file in $(ls frames/*.png); do convert $file -type truecolor -thumbnail 85x64 frames/$(basename $file .png).bmp; done
$ rm frames/*.png
```

> ffmpeg has an option to export bitmaps but I always get some distortion. With this everything 
> works fine (but the image files are a little bit larger).

Next we need to extract the audio:

```bash
$ ffmpeg -i bad-apple.mp4 bad-apple.mp3
```

> If you have used a different download link you need to change the maximum number of frames:
> 1. Go to the file `src/Main.elm`
> 2. Search for the function `currentFrame`
> 3. Set the maximum number to you value. This video has 7777 frames:
> ```elm
> currentFrame : Model -> Int
> currentFrame model =
>     ...
>     |> min 7777
> ```

And we build our site:

```bash
$ elm make --output=index.html src/Main.elm
```

Now you upload the directory to your web server (that depends on what server you use).

> There a many small frames. For that its better if you pack all the files, upload them and unpack 
> them:
> 
> ```bash
> # pack the frames
> $ tar cvzf frames.tar.gz frames
> # upload your files
> # ...
> # unpack the frames
> $ tar xvzf frames.tar.gz
> ```

Thats it. Now you can watch `index.html` with your favorite web browser.

## Audio doesn't work

You need to enable the automatic start of video and audio in your browser and reload the page.
