make_grilo_find_plugins() {
    # For packages that need gschemas of other packages (e.g. empathy)
    if [ -d "$1"/lib/grilo-0.2 ]; then
        addToSearchPath GRL_PLUGIN_PATH "$1/lib/grilo-0.2"
    fi
}

envHooks+=(make_grilo_find_plugins)
