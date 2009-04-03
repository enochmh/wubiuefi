export SHELL = sh
PACKAGE = wubi
ICON = data/images/Wubi.ico
REVISION = $(shell bzr revno)
VERSION = $(shell head -n 1 debian/changelog | sed -e "s/^$(PACKAGE) (\(.*\)).*/\1/g")
COPYRIGHTYEAR = 2009
AUTHOR = Agostino Russo
EMAIL = agostino.russo@gmail.com

all: build

build: wubi

wubi: wubi-pre-build
	PYTHONPATH=src tools/pywine -OO build/pylauncher/pack.py --dir=build/wubi src/main.py data build/bin build/version.py build/winboot build/translations
	mv build/wubi/application.exe build/wubi.exe

wubizip: wubi-pre-build
	PYTHONPATH=src tools/pywine build/pylauncher/pack.py --dir=build/wubi --nopyc src/main.py data build/bin build/version.py build/winboot build/translations
	cp wine/drive_c/Python23/python.exe build/wubi/files #TBD
	cp build/cpuid/cpuid.dll build/bin
	mv build/wubi/files build/wubi/wubi
	cd build/wubi; zip -r ../wubi.zip wubi
	mv build/wubi/wubi build/wubi/files

wubi-pre-build: check_wine pylauncher winboot src/main.py src/wubi/*.py cpuid version.py translations
	rm -rf build/wubi
	rm -rf build/bin
	cp -a blobs build/bin
	cp wine/drive_c/Python23/pythonw.exe build/pylauncher #TBD
	cp wine/drive_c/windows/system32/python23.dll build/pylauncher #TBD
	cp build/cpuid/cpuid.dll build/bin

pot:
	xgettext --default-domain="$(PACKAGE)" --output="po/$(PACKAGE).pot" $(shell find src/wubi -name "*.py")
	sed -i 's/SOME DESCRIPTIVE TITLE/Translation template for $(PACKAGE)/' po/$(PACKAGE).pot
	sed -i "s/YEAR THE PACKAGE'S COPYRIGHT HOLDER/$(COPYRIGHTYEAR)/" po/$(PACKAGE).pot
	sed -i 's/FIRST AUTHOR <EMAIL@ADDRESS>, YEAR/$(AUTHOR) <$(EMAIL)>, $(COPYRIGHTYEAR)/' po/$(PACKAGE).pot
	sed -i 's/Report-Msgid-Bugs-To: /Report-Msgid-Bugs-To: $(EMAIL)/' po/$(PACKAGE).pot
	sed -i 's/CHARSET/UTF-8/' po/$(PACKAGE).pot
	sed -i 's/PACKAGE VERSION/$(VERSION)-r$(REVISION)/' po/$(PACKAGE).pot
	sed -i 's/PACKAGE/$(PACKAGE)/' po/$(PACKAGE).pot

translations: po/*.po
	mkdir -p build/translations/
	@for po in $^; do \
		language=`basename $$po`; \
		language=$${language%%.po}; \
		target="build/translations/$$language/LC_MESSAGES"; \
		mkdir -p $$target; \
		msgfmt --output=$$target/$(PACKAGE).mo $$po; \
	done

version.py:
	$(shell echo 'version = "$(VERSION)"' > build/version.py)
	$(shell echo 'revision = $(REVISION)' >> build/version.py)
	$(shell echo 'application_name = "$(PACKAGE)"' >> build/version.py)

pylauncher: 7z src/pylauncher/*
	cp -rf src/pylauncher build
	cp "$(ICON)" build/pylauncher/application.ico
	sed -i 's/application_name/$(PACKAGE)/' build/pylauncher/pylauncher.exe.manifest
	cd build/pylauncher; make

cpuid: src/cpuid/cpuid.c
	cp -rf src/cpuid build
	cd build/cpuid; make

winboot: grub4dos grubutil
	mkdir -p build/winboot
	cp -f data/menu.winboot build/winboot/menu.lst
	cp -f build/grub4dos/stage2/grldr build/winboot/wubildr
	cp -f build/grub4dos/stage2/grub.exe build/winboot/wubildr.exe
	dd if=build/winboot/wubildr of=build/winboot/wubildr.mbr bs=1 count=8192
	cd build/winboot; ../grubutil/grubinst/grubinst -o -b=wubildr wubildr.mbr

grub4dos: src/grub4dos/*
	cp -rf src/grub4dos build
	cd build/grub4dos;./configure --enable-preset-menu=../../data/menu.winboot
	cd build/grub4dos; make

grubutil: src/grubutil/grubinst/*
	cp -rf src/grubutil build
	cd build/grubutil/grubinst; make

# not compiling 7z at the moment, but source is used by pylauncher
7z: src/7z/C/*.c
	cp -rf src/7z build

runbin: wubi
	rm -rf build/test
	mkdir build/test
	cd build/test; ../../tools/wine ../wubi.exe --test

check_wine: tools/check_wine
	tools/check_wine

unittest:
	tools/pywine tools/test

runpy:
	PYTHONPATH=src tools/pywine src/main.py --test

clean:
	rm -rf dist/*
	rm -rf build/*

.PHONY: all build test wubi wubizip wubi-pre-build pot runpy runbin ckeck_wine unittest
	7z translations version.py pylauncher winboot grubutil grub4dos
