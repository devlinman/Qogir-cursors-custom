# Qogir cursors with *fucking* 

## Look, I like these cursors. 
## I neeeed them. 

And Plasma just removed them from themes (after updating to Plasma 6.6).

So I tried building from source....

And the build system is..... hmmmmmm...

I made my own `better_fucking_build.sh` file.

It builds the cursors from the svgs using `inkscape` and `xcursorgen`, for any given size.

I need size `40`. You may want to customize the sizes in `SIZES` variable.

Also modified the `install.sh` file to only install the required theme. I don't need the manjaro or ubuntu version.

### I didn't want to fork the entire Qogir icon theme repo. 

### I am simply interested in the cursors.

- I should make it clear: I did not make the icons, nor do I own them.

- They are lisenced under **GPLv3** in the original github repo.

I added a new build script, that's all.

I have mentioned the changes I made as stipulated by the license.

This repo is also lisenced under **GPLv3**.

And I am not using this for any commercial purposes. Just eye-candy.

K. Bye.

Information about the source repo is found below.

--- 

---

---
# Original Repo link: [Qogir-icon-theme](https://github.com/vinceliuice/Qogir-icon-theme)

## Cursors found inside `src/cursors` in the original repo.

This is an x-cursor theme inspired by Qogir theme and
based on [capitaine-cursors](https://github.com/keeferrourke/capitaine-cursors).

Windows version [Qogir-cursors](https://github.com/CodyJH/Qogir-Cursors-Windows)

## Installation
To install the cursor theme simply copy the compiled theme to your icons
directory. For local user installation:

```
./install.sh
```

For system-wide installation for all users:

```
sudo ./install.sh
```

Then set the theme with your preferred desktop tools.

## Building from source
You'll find everything you need to build and modify this cursor set in
the `src/` directory. To build the xcursor theme from the SVG source
run:

```
./build.sh
```

This will generate the pixmaps and appropriate aliases.
The freshly compiled cursor theme will be located in `dist/`

## Preview
![Qogir](preview.png)
![Qogir-white](preview-white.png)
