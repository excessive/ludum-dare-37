PROJECT_SHORTNAME=ld37-excessive

LOVE=love
LOVE_VERSION=0.10.2
SRC_DIR=.
GIT_HASH=$(shell git log --pretty=format:'%h' -n 1 ${SRC_DIR})
GIT_COUNT=$(shell git log --pretty=format:'' ${SRC_DIR} | wc -l)
GIT_TARGET=${SRC_DIR}/git.lua
WORKING_DIRECTORY=$(shell pwd)

LOVE_TARGET=${PROJECT_SHORTNAME}.love

DEPS_DATA=resources/build_data
DEPS_DOWNLOAD_TARGET=https://bitbucket.org/rude/love/downloads/
DEPS_WIN32_TARGET=love-${LOVE_VERSION}\-win64.zip
DEPS_WIN64_TARGET=love-${LOVE_VERSION}\-win32.zip
DEPS_MACOS_TARGET=love-${LOVE_VERSION}\-macosx-x64.zip

BUILD_INFO=v${GIT_COUNT}-[${GIT_HASH}]
BUILD_BIN_NAME=${PROJECT_SHORTNAME}_${BUILD_INFO}
BUILD_DIR=builds
BUILD_LOVE=${PROJECT_SHORTNAME}_${BUILD_INFO}
BUILD_WIN32=${PROJECT_SHORTNAME}_win32_${BUILD_INFO}
BUILD_WIN64=${PROJECT_SHORTNAME}_win64_${BUILD_INFO}
BUILD_MACOS=${PROJECT_SHORTNAME}_macosx_${BUILD_INFO}

BUTLER=~/.config/itch/bin/butler
BUTLER_VERSION=${GIT_COUNT}[git:${GIT_HASH}]
BUTLER_GAME=ldex
BUTLER_USER=excessive

.PHONY: clean
clean:
	#Remove generated `${GIT_TARGET}`
	rm -f ${GIT_TARGET}

.PHONY: cleanlove
cleanlove:
	rm -f ${LOVE_TARGET}

.PHONY: love
love: clean
	#Writing ${GIT_TARGET}
	echo "git_hash,git_count = '${GIT_HASH}',${GIT_COUNT}" > ${GIT_TARGET}
	#Make love file
	zip -9 \
		-x ".vscode*" -x ".swp" -x "*.atom-build.json" -x "*Makefile" \
		-x ".git*" -x "*.git" -x "*.gitignore" \
		-x "*.yml" -x "*.editorconfig" \
		-x "*_spec.lua" -x "*.rockspec" \
		-x "resources/*" -x "*.love" \
		-r ${LOVE_TARGET} .

.PHONY: run
run: love
	exec ${LOVE} --fused ${LOVE_TARGET}

.PHONY: debug
debug:
	exec ${LOVE} --fused ${SRC_DIR} --debug --hud

.PHONY: cleandeps
cleandeps:
	rm -rf ${DEPS_DATA}

.PHONY: deps
deps:
	# Download binaries, and unpack
	mkdir -p ${DEPS_DATA}; \
	cd ${DEPS_DATA}; \
	\
	wget -t 2 -c ${DEPS_DOWNLOAD_TARGET}${DEPS_WIN32_TARGET};\
	unzip -o ${DEPS_WIN32_TARGET};\
	\
	wget -t 2 -c ${DEPS_DOWNLOAD_TARGET}${DEPS_WIN64_TARGET};\
	unzip -o ${DEPS_WIN64_TARGET};\
	\
	wget -t 2 -c ${DEPS_DOWNLOAD_TARGET}${DEPS_MACOS_TARGET};\
	unzip -o ${DEPS_MACOS_TARGET};\
	\
	cd -

.PHONY: build_love
build_love: love
	mkdir -p ${BUILD_DIR}
	cp ${LOVE_TARGET} ${BUILD_DIR}/${BUILD_LOVE}.love

.PHONY: build_win32
build_win32: love
	mkdir -p ${BUILD_DIR}
	$(eval TMP := $(shell mktemp -d))
	cat ${DEPS_DATA}/love-${LOVE_VERSION}\-win32/love.exe ${LOVE_TARGET} > ${TMP}/${BUILD_BIN_NAME}.exe
	cp ${DEPS_DATA}/love-${LOVE_VERSION}\-win32/*.dll ${TMP}
	zip -rj ${BUILD_DIR}/${BUILD_WIN32} $(TMP)/*
	rm -rf $(TMP)

.PHONY: build_win64
build_win64: love
	mkdir -p ${BUILD_DIR}
	$(eval TMP := $(shell mktemp -d))
	cat ${DEPS_DATA}/love-${LOVE_VERSION}\-win64/love.exe ${LOVE_TARGET} > ${TMP}/${BUILD_BIN_NAME}.exe
	cp ${DEPS_DATA}/love-${LOVE_VERSION}\-win64/*.dll ${TMP}
	zip -rj ${BUILD_DIR}/${BUILD_WIN64} $(TMP)/*
	rm -rf $(TMP)

.PHONY: build_macos
build_macos: love
	mkdir -p ${BUILD_DIR}
	$(eval TMP := $(shell mktemp -d))
	cp ${DEPS_DATA}/love.app/ ${TMP}/${BUILD_BIN_NAME}.app -Rv
	cp ${LOVE_TARGET} ${TMP}/${BUILD_BIN_NAME}.app/Contents/Resources/${BUILD_BIN_NAME}.love
	cd ${TMP}; \
	zip -ry ${WORKING_DIRECTORY}/${BUILD_DIR}/${BUILD_MACOS}.zip ${BUILD_BIN_NAME}.app/
	cd ${WORKING_DIRECTORY}
	rm -rf $(TMP)

.PHONY: all
all: build_love build_win32 build_win64 build_macos

.PHONY: deploy
deploy: all
	${BUTLER} login
	${BUTLER} push ${BUILD_DIR}/${BUILD_LOVE}.love ${BUTLER_USER}/${BUTLER_GAME}:love\
		--userversion ${BUTLER_VERSION}
	${BUTLER} push ${BUILD_DIR}/${BUILD_WIN32}.zip ${BUTLER_USER}/${BUTLER_GAME}:win32\
		--userversion ${BUTLER_VERSION}
	${BUTLER} push ${BUILD_DIR}/${BUILD_WIN64}.zip ${BUTLER_USER}/${BUTLER_GAME}:win64\
		--userversion ${BUTLER_VERSION}
	${BUTLER} push ${BUILD_DIR}/${BUILD_MACOS}.zip ${BUTLER_USER}/${BUTLER_GAME}:macosx\
		--userversion ${BUTLER_VERSION}
	${BUTLER} status ${BUTLER_USER}/${BUTLER_GAME}

.PHONY: status
status:
	#VERSION: ${BUILD_INFO}
	${BUTLER} status ${BUTLER_USER}/${BUTLER_GAME}
