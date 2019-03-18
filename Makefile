build/popup_calc: src/expressions.vala src/main.vala src/popup.vala
	mkdir -p build
	valac --pkg gtk+-3.0 src/*.vala -o build/popup_calc

install: build/popup_calc
	mkdir -p ~/.local/share/popup_calc
	cp build/popup_calc ~/.local/share/popup_calc
	cat popup_calc.desktop | sed -E "s/USERNAME/${USER}/g" > ~/.local/share/applications/popup_calc.desktop
	cp popup_calc.svg ~/.local/share/icons/hicolor/48x48/apps/
	chmod +x ~/.local/share/applications/popup_calc.desktop

uninstall:
	rm -rf ~/.local/share/popup_calc
	rm -f ~/.local/share/applications/popup_calc.desktop
	rm -f ~/.local/share/icons/hicolor/48x48/apps/popup_calc.svg

clean:
	rm -rf build
