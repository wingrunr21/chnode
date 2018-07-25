CHNODE_VERSION="1.0.0"
NODES=()

function chnode_refresh()
{
	local search
	search=($PREFIX/opt/nodes $HOME/.nodes)
	local brewexec brewdir brewcellar
	
	[ -n "$ZSH_NAME" ] && setopt localoptions nullglob KSH_ARRAYS
	if [[ -x "$(command -v brew)" ]]; then
		brewcellar="$(brew --cellar 2>/dev/null)"
		if [[ -d "$brewcellar" ]]; then
			search+=("${brewcellar}"/node{,[0-9@]}*) 2>/dev/null || true
		fi
	fi
	for dir in "${search[@]}"; do
		[[ -d "$dir" && -n "$(ls -A "$dir")" ]] && NODES+=("$dir"/*)
	done

	return
}
chnode_refresh

function chnode_reset()
{
	[[ -z "$NODE_ROOT" ]] && return

	PATH=":$PATH:"; PATH="${PATH//:$NODE_ROOT\/bin:/:}"
	PATH="${PATH#:}"; PATH="${PATH%:}"
	unset NODE_ROOT NODE_ENGINE NODE_VERSION
	hash -r
}

function chnode_use()
{
	if [[ ! -x "$1/bin/node" ]]; then
		echo "chnode: $1/bin/node not executable" >&2
		return 1
	fi

	[[ -n "$NODE_ROOT" ]] && chnode_reset

	export NODE_ROOT="$1"
	export NODE_ENGINE="node"
	export PATH="$NODE_ROOT/bin:$PATH"
	export NODE_VERSION=$(node -v)

	hash -r
}

function chnode()
{
	case "$1" in
		-h|--help)
			echo "usage: chnode [NODE|VERSION|system]"
			;;
		-V|--version)
			echo "chnode: $CHNODE_VERSION"
			;;
		"")
			local dir node
			for dir in "${NODES[@]}"; do
				dir="${dir%%/}"; node="${dir##*/}"
				echo " * ${node}"
			done
			;;
		system) chnode_reset ;;
		*)
			local dir node match
			for dir in "${NODES[@]}"; do
				dir="${dir%%/}"; node="${dir##*/}"
				version="${node//[^0-9.]/}"
				case "${version}" in
					"$1") match="$dir" && break ;;
					"$1".*   | \
					"$1".*.* | \
					"$1"-*   | \
					"$1"_*   )	match="$dir" ;;
				esac
			done

			if [[ -z "$match" ]]; then
				echo "chnode: unknown Node: $1" >&2
				return 1
			fi

			shift
			chnode_use "$match"
			;;
	esac
}
