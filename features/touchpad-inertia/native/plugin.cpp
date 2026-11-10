// Extend vertical finger scrolling for selected terminals and Omarchy menus.
#include "ScrollState.hpp"
#include "WindowPolicy.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/config/ConfigValue.hpp>
#include <hyprland/src/config/values/types/FloatValue.hpp>
#include <hyprland/src/config/values/types/StringValue.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/view/LayerSurface.hpp>
#include <hyprland/src/helpers/time/Time.hpp>
#include <hyprland/src/managers/SeatManager.hpp>
#include <hyprland/src/managers/SessionLockManager.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/protocols/InputCapture.hpp>

#include <stdexcept>
#include <vector>

namespace {

constexpr int FrameMs = 16;
TouchpadInertia::ScrollState scroll;
wl_event_source* timer = nullptr;
WP<CWLSurfaceResource> target;
PHLWINDOWREF owner;
bool emitted = false;
std::vector<CHyprSignalListener> listeners;

struct PointerContact {
    WP<IPointer> pointer;
    CHyprSignalListener hold;
};
std::vector<PointerContact> contacts;

uint64_t nowMs() { return Time::millis(Time::steadyNow()); }

void emit(double delta) {
    g_pSeatManager->sendPointerAxis(static_cast<uint32_t>(nowMs()), WL_POINTER_AXIS_VERTICAL_SCROLL,
        delta, 0, 0, WL_POINTER_AXIS_SOURCE_FINGER, WL_POINTER_AXIS_RELATIVE_DIRECTION_IDENTICAL);
    g_pSeatManager->sendPointerFrame();
}

void stop() {
    if (emitted && g_pSeatManager && target.lock() && target.lock() == g_pSeatManager->m_state.pointerFocus.lock())
        emit(0);
    emitted = false;
    scroll.reset();
    target.reset();
    owner.reset();
    if (timer) wl_event_source_timer_update(timer, 0);
}

struct ScrollTarget {
    SP<CWLSurfaceResource> surface;
    PHLWINDOW window;
};

ScrollTarget eligibleTarget() {
    if (!g_pSeatManager || !g_pInputManager || !g_pSessionLockManager ||
        g_pSessionLockManager->isSessionLocked() || g_pInputManager->isLocked() ||
        g_pInputManager->getModsFromAllKBs() != 0 || g_pSeatManager->m_seatGrab ||
        (PROTO::inputCapture && PROTO::inputCapture->isCaptured()))
        return {};
    const auto surface = Desktop::View::CWLSurface::fromResource(g_pSeatManager->m_state.pointerFocus.lock());
    const auto view = surface ? surface->view() : nullptr;
    if (!view) return {};
    if (view->type() == Desktop::View::VIEW_TYPE_LAYER_SURFACE) {
        const auto layer = Desktop::View::CLayerSurface::fromView(view);
        const auto namespaces = CConfigValue<Config::STRING>("plugin:touchpad-inertia:layers");
        if (layer && layer->visible() && TouchpadInertia::listed(layer->m_namespace, *namespaces) &&
            g_pSeatManager->m_state.keyboardFocus.lock() == surface->resource())
            return {surface->resource(), nullptr};
        return {};
    }
    if (view->type() != Desktop::View::VIEW_TYPE_WINDOW) return {};
    const auto window = Desktop::View::CWindow::fromView(view);
    if (!window || window->m_isX11 || !window->m_isMapped || window->isHidden() || !window->visible() ||
        window->isInputBlocked() || window != Desktop::focusState()->window() ||
        !window->getWindowMainSurfaceBox().containsPoint(g_pInputManager->getMouseCoordsInternal()))
        return {};
    const auto classes = CConfigValue<Config::STRING>("plugin:touchpad-inertia:classes");
    if (!TouchpadInertia::allowed(window->m_class, window->m_initialTitle, *classes))
        return {};
    return {surface->resource(), window};
}

// The input event already carries libinput's configured natural-scroll sign.
// Apply the same touchpad/device/window factors used by Hyprland's axis path.
double scaleFor(const PHLWINDOW& window) {
    const auto factor = CConfigValue<Config::FLOAT>("input:touchpad:scroll_factor");
    double result = *factor;
    const auto pointer = g_pSeatManager->m_mouse.lock();
    if (pointer && pointer->m_scrollFactor.has_value()) result = *pointer->m_scrollFactor;
    if (window && window->isScrollTouchpadOverridden()) result = window->getScrollTouchpad();
    return result;
}

int advance(void*) {
    const auto current = eligibleTarget();
    if (!current.surface || current.window != owner.lock() || target.lock() != current.surface) {
        stop();
        return 0;
    }
    const auto decay = CConfigValue<Config::FLOAT>("plugin:touchpad-inertia:decay_ms");
    const double delta = scroll.advance(nowMs(), *decay) * scaleFor(current.window);
    if (!scroll.decaying() || !std::isfinite(delta) || delta == 0) {
        stop();
        return 0;
    }
    emit(delta);
    emitted = true;
    wl_event_source_timer_update(timer, FrameMs);
    return 0;
}

void connectContacts() {
    if (!g_pInputManager) return;
    std::erase_if(contacts, [](const auto& entry) { return entry.pointer.expired(); });
    for (const auto& pointer : g_pInputManager->m_pointers) {
        if (!pointer->m_isTouchpad || std::ranges::any_of(contacts, [&](const auto& entry) { return entry.pointer.lock() == pointer; }))
            continue;
        contacts.push_back({pointer, pointer->m_pointerEvents.holdBegin.listen([] { stop(); })});
    }
}

void onAxis(const IPointer::SAxisEvent& event, Event::SCallbackInfo& info) {
    connectContacts();
    // The focus plugin can consume a horizontal axis-stop accompanying a short
    // vertical gesture. Its zero delta must not cancel an established vertical tail.
    if (info.cancelled && event.axis == WL_POINTER_AXIS_HORIZONTAL_SCROLL && event.delta == 0)
        return;
    if (info.cancelled || event.source != WL_POINTER_AXIS_SOURCE_FINGER) {
        stop();
        return;
    }
    const auto current = eligibleTarget();
    if (!current.surface) {
        stop();
        return;
    }
    if (current.window != owner.lock() || current.surface != target.lock() || (scroll.decaying() && event.delta != 0))
        stop();
    owner = current.window;
    target = current.surface;
    const auto now = nowMs();
    if (event.axis == WL_POINTER_AXIS_HORIZONTAL_SCROLL) {
        scroll.horizontal(event.delta, now);
        return;
    }
    if (event.delta != 0)
        scroll.vertical(event.delta, now);
    else if (scroll.release(now))
        wl_event_source_timer_update(timer, FrameMs);
    // Physical events are delivered by Hyprland unchanged. Synthetic momentum
    // goes directly to the seat and never re-enters the horizontal focus plugin.
}

} // namespace

APICALL EXPORT std::string PLUGIN_API_VERSION() { return HYPRLAND_API_VERSION; }

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    if (HyprlandAPI::getHyprlandVersion(handle).hash != GIT_COMMIT_HASH)
        throw std::runtime_error("touchpad-inertia must be rebuilt for this Hyprland version");
    using namespace Config::Values;
    if (!HyprlandAPI::addConfigValueV2(handle, makeShared<CStringValue>("plugin:touchpad-inertia:classes",
            "Exact terminal classes eligible for vertical inertia", "foot,org.codeberg.dnkl.foot")) ||
        !HyprlandAPI::addConfigValueV2(handle, makeShared<CStringValue>("plugin:touchpad-inertia:layers",
            "Exact keyboard-focused layer namespaces eligible for vertical inertia", "omarchy-menu")) ||
        !HyprlandAPI::addConfigValueV2(handle, makeShared<CFloatValue>("plugin:touchpad-inertia:decay_ms",
            "Vertical momentum decay time in milliseconds", 180.F, SFloatValueOptions{.min = 40.F, .max = 600.F})))
        throw std::runtime_error("Could not register touchpad inertia options");
    timer = wl_event_loop_add_timer(g_pCompositor->m_wlEventLoop, advance, nullptr);
    if (!timer) throw std::runtime_error("Could not create touchpad inertia timer");

    auto& events = Event::bus()->m_events;
    listeners.push_back(events.input.mouse.axis.listen(onAxis));
    listeners.push_back(events.input.mouse.button.listen([] { stop(); }));
    listeners.push_back(events.input.keyboard.key.listen([] { stop(); }));
    listeners.push_back(events.input.mouse.move.listen([] { if (scroll.decaying()) stop(); }));
    listeners.push_back(events.gesture.swipe.begin.listen([] { stop(); }));
    listeners.push_back(events.gesture.pinch.begin.listen([] { stop(); }));
    listeners.push_back(events.config.preReload.listen([] { stop(); }));
    listeners.push_back(events.config.reloaded.listen([] { stop(); connectContacts(); }));
    listeners.push_back(g_pSeatManager->m_events.keyboardFocusChange.listen([] { stop(); }));
    listeners.push_back(g_pSeatManager->m_events.pointerFocusChange.listen([] { stop(); }));
    connectContacts();
    return {"touchpad-inertia", "Vertical touchpad momentum for terminals and menus", "Omarchy MacBook", "1.0.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    listeners.clear();
    contacts.clear();
    stop();
    if (timer) wl_event_source_remove(timer);
    timer = nullptr;
}
