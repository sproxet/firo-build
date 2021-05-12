# This provides wrappers for various functions so that binaries will be created deterministically.

if [[ "$(basename $0)" = "faketime.sh" ]]; then
  echo "This file should be loaded with source, not executed directly." >&2
  exit 1
fi

HOSTS="x86_64-linux-gnu x86_64-apple-darwin14 x86_64-w64-mingw32"

WRAP_DIR="$HOME/wrapped"
mkdir -p "$WRAP_DIR"

export QT_RCC_SOURCE_DATE_OVERRIDE=1
export TAR_OPTIONS="--mtime=@0"
export GZIP="-9n"
export TZ="UTC"

for prog in date ar ranlib nm; do
  cat >"$WRAP_DIR/$prog" <<END
#!/bin/bash
REAL="\$(which -a $prog | grep -v $WRAP_DIR/$prog | head -1)"
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1
export FAKETIME="2000-01-01 12:00:00"
\$REAL \$@
END
  chmod +x "$WRAP_DIR/$prog"
done

for host in $HOSTS; do
  for prog in gcc g++; do
      if which "$host-$prog-8"; then
        cat >"$WRAP_DIR/$host-$prog" <<END
#!/usr/bin/env bash
REAL="$(which -a "$host-$prog-8" | grep -v "$WRAP_DIR/$host-$prog" | head -1)"
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1
export FAKETIME="2000-01-01 12:00:00"
\$REAL \$@
END
      chmod +x "$WRAP_DIR/$host-$prog"
    fi
  done
done

export PATH="$WRAP_DIR:$PATH"

EXTRA_INCLUDES_BASE="$WRAP_DIR/extra_includes"
mkdir -p "$EXTRA_INCLUDES_BASE"

# x86 needs /usr/include/i386-linux-gnu/asm pointed to /usr/include/x86_64-linux-gnu/asm,
# but we can't write there. Instead, create a link here and force it to be included in the
# search paths by wrapping gcc/g++.

mkdir -p "$EXTRA_INCLUDES_BASE/i686-pc-linux-gnu"
rm -f "$WRAP_DIR/extra_includes/i686-pc-linux-gnu/asm"
ln -s /usr/include/x86_64-linux-gnu/asm "$EXTRA_INCLUDES_BASE/i686-pc-linux-gnu/asm"

for prog in gcc g++; do
  cat >"$WRAP_DIR/$prog" <<END
#!/usr/bin/env bash
REAL=\`which -a "$prog" | grep -v "$WRAP_DIR/$prog" | head -1\`
for arg in "\$@"; do
  if [ "\$arg" = "-m32" ]; then
    export C_INCLUDE_PATH="$EXTRA_INCLUDES_BASE/i686-pc-linux-gnu"
    export CPLUS_INCLUDE_PATH="$EXTRA_INCLUDES_BASE/i686-pc-linux-gnu"
    break
  fi
done
\$REAL \$@
END
  chmod +x "$WRAP_DIR/$prog"
done