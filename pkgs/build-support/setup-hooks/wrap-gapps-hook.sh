wrapGAppsHook() {
  local args=()

  if [ -n "$GDK_PIXBUF_MODULE_FILE" ]; then
    args+=(--set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE")
  fi

  if [ -n "$XDG_ICON_DIRS" ]; then
    addToSearchPath XDG_DATA_DIRS : "$XDG_ICON_DIRS"
  fi

  if [ -n "$GSETTINGS_SCHEMAS_PATH" ]; then
    args+=(--prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH")
  fi

  if [ -d "$prefix/share" ]; then
    args+=(--prefix XDG_DATA_DIRS : "$out/share")
  fi

  for v in $wrapPrefixVariables GST_PLUGIN_SYSTEM_PATH_1_0 GI_TYPELIB_PATH GRL_PLUGIN_PATH; do
    eval local dummy="\$$v"
    args+=(--prefix $v : "$dummy")
  done

  for i in $prefix/bin/* $prefix/libexec/*; do
    echo "Wrapping app $i"
    wrapProgram "$i" ${args[@]}
  done
}

fixupOutputHooks+=(wrapGAppsHook)
