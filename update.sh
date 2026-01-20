#!/bin/bash

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$WORK_DIR/update.log"
REPOS_DIR="$WORK_DIR/repos"
DEBUG_FLAG="FALSE"

log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_debug() {
	for arg in "$@"; do
		if [[ "$arg" == "-d" ]]; then
			DEBUG_FLAG="TRUE"
			log "Debug mode enabled"
			break
		fi
	done
}

build_pkg() {
	local PKG_DIR="$1"
	docker run --rm \
		-v "$PKG_DIR":/pkg \
		"$DOCKER_IMAGE" \
		/bin/bash -c "$2" |
		tee -a "$LOG_FILE"
}

commit() {
	local PKG_NAME="$1"
	if git status --porcelain | grep -E '.SRCINFO'; then
		log "$PKG_NAME build completed, .SRCINFO has changes"
		if [[ "$DEBUG_FLAG" == "TRUE" ]]; then
			log "Debug mode enabled, skipping commit and push"
			return
		else
			log "$PKG_NAME commit and push"
		fi
		git add PKGBUILD .SRCINFO
		NEW_VER=$(grep "pkgver =" .SRCINFO | head -1 | awk '{print $3}')
		git commit -m "Update to $NEW_VER"
		GIT_SSH_COMMAND='ssh -i $WORK_DIR/aur -o IdentitiesOnly=yes' git push origin master
	else
		log "$PKG_NAME no commit needed"
	fi
}

check_debug "$@"

find "$REPOS_DIR" -maxdepth 1 -mindepth 1 -type d | sort | while read -r PKG_DIR; do
	PKG_NAME=$(basename "$PKG_DIR")
	cd "$PKG_DIR" || {
		log "Failed to enter $PKG_DIR, skipping"
		continue
	}
	log "Processing package: $PKG_NAME"
	log "Pulling latest code..."
	git pull origin master | tee -a "$LOG_FILE"

	case "$PKG_NAME" in
	*-git)
		log "Building $PKG_NAME (git package)..."
		build_pkg "$PKG_DIR" "makepkg -co --nodeps && makepkg --printsrcinfo > .SRCINFO"
		;;
	ttf-lxgw-neo-zhisong-screen)
		CURRENT_VER=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
		REPO_URL=$(grep "^url=" PKGBUILD | cut -d'"' -f2 | cut -d"'" -f2)
		LATEST_TAG_URL=$(curl -Ls -o /dev/null -w %{url_effective} "$REPO_URL/releases/latest")
		LATEST_VER=$(basename "$LATEST_TAG_URL" | sed 's/^v//')
		log "Current version: $CURRENT_VER, Latest version: $LATEST_VER"
		if [ "$CURRENT_VER" == "$LATEST_VER" ]; then
			log "$PKG_NAME is up to date, no update needed"
			continue
		fi
		log "Updating PKGBUILD version number..."
		sed -i "s/^pkgver=.*/pkgver=$LATEST_VER/" PKGBUILD
		sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
		log "Building $PKG_NAME ..."
		build_pkg "$PKG_DIR" "updpkgsums && makepkg --printsrcinfo > .SRCINFO"
		;;
	wps-office-365-edu)
		CURRENT_VER=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
		log "Current version: $CURRENT_VER"
		bash ./update.sh | tee -a "$LOG_FILE"
		LATEST_VER=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
		log "Latest version: $LATEST_VER"
		if [ "$CURRENT_VER" == "$LATEST_VER" ]; then
			log "$PKG_NAME is up to date, no update needed"
			continue
		fi
		log "Building $PKG_NAME ..."
		build_pkg "$PKG_DIR" "updpkgsums && makepkg --printsrcinfo > .SRCINFO"
		;;
	ednovas-cloud)
		CURRENT_VER=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
		log "Current version: $CURRENT_VER"
		bash ./update.sh | tee -a "$LOG_FILE"
		LATEST_VER=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
		log "Latest version: $LATEST_VER"
		if [ "$CURRENT_VER" == "$LATEST_VER" ]; then
			log "$PKG_NAME is up to date, no update needed"
			continue
		fi
		log "Building $PKG_NAME ..."
		build_pkg "$PKG_DIR" "updpkgsums && makepkg --printsrcinfo > .SRCINFO"
		;;
	esac

	commit "$PKG_NAME"
done
