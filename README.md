# popup-calc

A Spotlight-style calculator for quick arithmetic.

![Screenshot of the app](screenshot.png)

# Building

Install some dependencies:

```
sudo apt install -y libgtk-3-dev valac
```

Compile the binary:

```
make
```

Install the desktop application, complete with a desktop shortcut and an icon:

```
make install
```

You can also uninstall the desktop application:

```
make uninstall
```

It is recommended that you bind the application to a keystroke. After a `make install`, the binary will be located at `~/.local/share/popup_calc/popup_calc`.