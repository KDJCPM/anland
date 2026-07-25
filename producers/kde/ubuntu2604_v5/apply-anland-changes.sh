#!/bin/bash
# apply-anland-changes.sh - Apply anland-specific changes to kwin source tree
# This replaces kwin.patch which is fragile against upstream changes.
# Run from the kwin source tree root after overlay.

set -e

TREE="${1:-.}"

echo "==> Applying anland changes to $TREE"

# 1. Add commitText() method to inputmethod.cpp (after commitPendingText)
if ! grep -q "void InputMethod::commitText" "$TREE/src/inputmethod.cpp"; then
    echo "  Adding commitText() to inputmethod.cpp"
    sed -i '/void InputMethod::commitPendingText/,/^$/a\
\
void InputMethod::commitText(const QString \&text)\
{\
    if (text.isEmpty()) {\
        return;\
    }\
    commitString(m_serial++, text);\
}' "$TREE/src/inputmethod.cpp"
fi

# 2. Add commitText() declaration to inputmethod.h
if ! grep -q "void commitText" "$TREE/src/inputmethod.h"; then
    echo "  Adding commitText() declaration to inputmethod.h"
    sed -i '/void commitPendingText();/a\
\
    // Inject committed text from a compositor-side input source (anland keyboard).\
    void commitText(const QString \&text);' "$TREE/src/inputmethod.h"
fi

# 3. Add add_subdirectory(anland) to backends/CMakeLists.txt
if ! grep -q "add_subdirectory(anland)" "$TREE/src/backends/CMakeLists.txt"; then
    echo "  Adding anland to CMakeLists.txt"
    sed -i '1i add_subdirectory(anland)' "$TREE/src/backends/CMakeLists.txt"
fi

# 4. Add anland backend include and option to main_wayland.cpp
if ! grep -q "anland_backend.h" "$TREE/src/main_wayland.cpp"; then
    echo "  Adding anland backend to main_wayland.cpp"
    # Add include after other backend includes
    sed -i '/#include "backends\/drm\/drm_backend.h"/i #include "backends/anland/anland_backend.h"' "$TREE/src/main_wayland.cpp"
    # Add command line option
    sed -i 's/QCommandLineOption drmOption/QCommandLineOption anlandOption("anland", i18n("Render to the anland display daemon."));\
    QCommandLineOption drmOption/' "$TREE/src/main_wayland.cpp"
    # Add parser option
    sed -i '/parser.addOption(drmOption)/a\    parser.addOption(anlandOption);' "$TREE/src/main_wayland.cpp"
fi

echo "==> Anland changes applied successfully"
