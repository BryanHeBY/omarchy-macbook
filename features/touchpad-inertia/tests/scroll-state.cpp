// Exercise release detection, velocity decay and horizontal gesture isolation.
#include "../native/ScrollState.hpp"
#include "../native/WindowPolicy.hpp"
#include <cassert>
#include <cmath>
#include <iostream>
#include <limits>

using TouchpadInertia::ScrollState;

ScrollState moving(double direction = 1) {
    ScrollState state;
    state.vertical(direction * 8, 1000);
    state.vertical(direction * 8, 1016);
    state.vertical(direction * 8, 1032);
    return state;
}

int main() {
    auto state = moving();
    assert(!state.decaying());
    assert(state.release(1040));
    const auto first = state.advance(1056, 180);
    const auto second = state.advance(1072, 180);
    assert(first > second && second > 0);
    for (uint64_t now = 1088; now < 3000; now += 16) state.advance(now, 180);
    assert(!state.decaying());

    state = moving(-1);
    assert(state.release(1040));
    assert(state.advance(1056, 180) < 0);
    state.reset();
    assert(!state.decaying() && state.advance(1100, 180) == 0);

    state = moving();
    assert(!state.release(1200)); // Stationary fingers must discard stale speed.
    state.vertical(8, 1300);
    assert(!state.release(1301)); // One sample cannot establish speed.
    state = moving();
    state.horizontal(60, 1033);
    assert(!state.release(1040)); // A recognized horizontal swipe has no tail.
    state = moving();
    state.horizontal(0.1, 1033);
    assert(state.release(1040)); // Small horizontal noise preserves vertical use.

    state = moving();
    state.vertical(-8, 1048);
    assert(state.release(1049));
    assert(state.advance(1065, 180) < 0); // Reversal must follow the latest direction.
    state = moving();
    assert(state.release(1040));
    assert(state.advance(2000, 180) == 0); // Resume after a long event-loop pause safely.
    state = moving();
    state.vertical(8, 900);
    assert(!state.release(901)); // A clock discontinuity starts a new sequence.
    state = moving();
    state.vertical(std::numeric_limits<double>::quiet_NaN(), 1040);
    assert(!state.release(1041));
    state = moving();
    state.horizontal(std::numeric_limits<double>::infinity(), 1040);
    assert(!state.release(1041));

    constexpr auto classes = "foot,org.codeberg.dnkl.foot";
    assert(TouchpadInertia::allowed("foot", "shell", classes));
    assert(TouchpadInertia::allowed("org.codeberg.dnkl.foot", "shell", classes));
    assert(TouchpadInertia::allowed("org.omarchy.agent", "foot", classes));
    assert(TouchpadInertia::allowed("TUI.float", "foot", classes));
    assert(!TouchpadInertia::allowed("org.omarchy.agent", "Alacritty", classes));
    assert(!TouchpadInertia::allowed("google-chrome", "foot", classes));
    assert(!TouchpadInertia::allowed("com.microsoft.VSCode", "foot", classes));
    assert(!TouchpadInertia::allowed("org.omarchy.agent", "foot", "Alacritty"));
    assert(TouchpadInertia::listed("omarchy-menu", "omarchy-menu, custom-list"));
    assert(!TouchpadInertia::listed("omarchy-audio", "omarchy-menu"));
    std::cout << "PASS touchpad momentum state, release timing, direction and target policy\n";
}
