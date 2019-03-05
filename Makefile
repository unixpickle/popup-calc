build/popup_calc: src/expressions.vala src/main.vala src/popup.vala
	mkdir -p build
	valac --pkg gtk+-3.0 src/*.vala -o build/popup_calc

clean:
	rm -rf build
