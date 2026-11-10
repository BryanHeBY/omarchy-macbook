#pragma once

// Use exact classes, with Foot-launched Omarchy TUIs identified by initial title.
#include <string_view>

namespace TouchpadInertia {

inline bool listed(std::string_view value, std::string_view classes) {
    auto start = classes.find_first_not_of(" ,\t\n");
    while (start != std::string_view::npos) {
        const auto end = classes.find_first_of(" ,\t\n", start);
        if (classes.substr(start, end - start) == value) return true;
        start = classes.find_first_not_of(" ,\t\n", end);
    }
    return false;
}

inline bool allowed(std::string_view windowClass, std::string_view initialTitle, std::string_view classes) {
    return listed(windowClass, classes) || (listed("foot", classes) && initialTitle == "foot" &&
        (windowClass.starts_with("org.omarchy.") || windowClass.starts_with("TUI.")));
}

} // namespace TouchpadInertia
