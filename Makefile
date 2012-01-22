
all: rokopher

rokopher: source/rokopher.brs
	zip -9 -r rokopher.zip . -x \*~ -x Makefile -x \*.zip

clean:
	rm rokopher.zip

install: rokopher
	@echo Installing rokopher.zip to $(ROKU_DEV_TARGET)
	@curl -s -S -F "mysubmit=Install" -F "archive=@rokopher.zip" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[["

