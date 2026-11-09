// Intercept touchpad horizontal scrolling only in an eligible tiled workspace.
// Build against the headers and compiler matching the running Hyprland process.
#include "GestureState.hpp"

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/config/shared/actions/ConfigActions.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/managers/SessionLockManager.hpp>
#include <hyprland/src/managers/SeatManager.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>

#include <algorithm>
#include <chrono>
#include <stdexcept>
#include <tuple>
#include <vector>

namespace {

TwoFingerFocus::GestureState gesture;
CHyprSignalListener axisListener;
CHyprSignalListener swipeListener;
CHyprSignalListener pinchListener;
CHyprSignalListener reloadListener;

std::vector<PHLWINDOW> tiledWindows() {
    const auto focused = Desktop::focusState()->window();
    if (!focused || focused->m_isFloating || !focused->m_workspace || !focused->m_workspace->isVisible() ||
        g_pSessionLockManager->isSessionLocked() || g_pInputManager->isLocked() || g_pInputManager->getModsFromAllKBs() != 0 ||
        Fullscreen::controller()->hasFullscreen(focused->m_workspace))
        return {};

    // Popups, layer-shell controls and floating windows retain their own scrolling.
    const auto surface = Desktop::View::CWLSurface::fromResource(g_pSeatManager->m_state.pointerFocus.lock());
    const auto view = surface ? surface->view() : nullptr;
    if (!view || view->type() != Desktop::View::VIEW_TYPE_WINDOW)
        return {};
    const auto pointed = Desktop::View::CWindow::fromView(view);
    if (!pointed || pointed->m_isFloating || pointed->m_workspace != focused->m_workspace)
        return {};

    std::vector<PHLWINDOW> windows;
    for (const auto& window : Desktop::windowState()->windows()) {
        if (window->m_workspace == focused->m_workspace && window->m_isMapped && !window->m_isFloating &&
            !window->isHidden() && !window->isInputBlocked() && window->visible() && window->logicalBox())
            windows.push_back(window);
    }
    if (windows.size() < 2 || std::find(windows.begin(), windows.end(), focused) == windows.end())
        return {};

    // Spatial order is stable across focus changes and includes stacked tiles.
    std::sort(windows.begin(), windows.end(), [](const auto& left, const auto& right) {
        const auto a = *left->logicalBox();
        const auto b = *right->logicalBox();
        return std::tie(a.x, a.y, left->m_stableID) < std::tie(b.x, b.y, right->m_stableID);
    });
    return windows;
}

void onAxis(const IPointer::SAxisEvent& event, Event::SCallbackInfo& info) {
    if (info.cancelled) {
        gesture.reset();
        return;
    }
    if (event.source != WL_POINTER_AXIS_SOURCE_FINGER)
        return;

    const auto windows = tiledWindows();
    const auto focused = Desktop::focusState()->window();
    const auto workspace = focused && focused->m_workspace ? focused->m_workspace->m_id : 0;
    const auto axis = event.axis == WL_POINTER_AXIS_HORIZONTAL_SCROLL ? TwoFingerFocus::Axis::Horizontal : TwoFingerFocus::Axis::Vertical;
    const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
    const auto result = gesture.update(axis, event.delta, now, !windows.empty(), workspace);
    info.cancelled = result.consume;
    if (result.step == 0)
        return;

    const auto current = std::find(windows.begin(), windows.end(), focused) - windows.begin();
    const auto count = static_cast<std::ptrdiff_t>(windows.size());
    const auto next = (current + result.step + count) % count;
    (void)Config::Actions::focus(windows[next]);
}

} // namespace

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    if (HyprlandAPI::getHyprlandVersion(handle).hash != GIT_COMMIT_HASH)
        throw std::runtime_error("two-finger-focus must be rebuilt for this Hyprland version");

    axisListener = Event::bus()->m_events.input.mouse.axis.listen(onAxis);
    swipeListener = Event::bus()->m_events.gesture.swipe.begin.listen([] { gesture.reset(); });
    pinchListener = Event::bus()->m_events.gesture.pinch.begin.listen([] { gesture.reset(); });
    reloadListener = Event::bus()->m_events.config.reloaded.listen([] { gesture.reset(); });
    return {"two-finger-focus", "Two-finger focus cycling in multi-window tiled workspaces", "Omarchy MacBook", "1.0.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    axisListener.reset();
    swipeListener.reset();
    pinchListener.reset();
    reloadListener.reset();
    gesture.reset();
}
