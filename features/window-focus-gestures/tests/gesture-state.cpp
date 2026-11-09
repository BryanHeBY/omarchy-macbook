// Regression coverage for scroll forwarding, context changes and one action per swipe.
#include "../native/GestureState.hpp"
#include <cassert>
#include <iostream>
#include <limits>

using TwoFingerFocus::Axis;
using TwoFingerFocus::GestureState;

int main() {
    GestureState state;
    auto result = state.update(Axis::Horizontal, 30, 1, false, 1);
    assert(!result.consume && result.step == 0);
    assert(!state.update(Axis::Horizontal, 30, 2, true, 1).consume);
    state.reset();

    result = state.update(Axis::Horizontal, 10, 10, true, 1);
    assert(result.consume && result.step == 0);
    assert(state.update(Axis::Horizontal, 10, 20, true, 1).step == 1);
    assert(state.update(Axis::Horizontal, 100, 30, true, 1).step == 0);
    assert(state.update(Axis::Horizontal, -100, 40, true, 1).step == 0);
    assert(state.update(Axis::Horizontal, 0, 50, true, 1).consume);
    assert(state.update(Axis::Horizontal, -20, 60, true, 1).step == -1);
    state.reset();

    result = state.update(Axis::Vertical, 30, 100, true, 1);
    assert(!result.consume && result.step == 0);
    assert(!state.update(Axis::Horizontal, 30, 110, true, 1).consume);
    state.reset();

    state.update(Axis::Horizontal, 10, 200, true, 1);
    assert(!state.update(Axis::Horizontal, 20, 210, true, 2).consume);
    state.reset();
    state.update(Axis::Horizontal, 10, 300, true, 1);
    assert(!state.update(Axis::Horizontal, 20, 310, false, 1).consume);
    assert(!state.update(Axis::Horizontal, 20, 320, true, 1).consume);
    state.reset();

    state.update(Axis::Vertical, 10, 400, true, 1);
    assert(state.update(Axis::Horizontal, 14, 410, true, 1).step == 0);
    assert(state.update(Axis::Horizontal, 6, 420, true, 1).step == 1);
    assert(state.update(Axis::Horizontal, 20, 900, true, 1).step == 1);
    assert(!state.update(Axis::Horizontal, std::numeric_limits<double>::quiet_NaN(), 910, true, 1).consume);
    assert(state.update(Axis::Horizontal, 20, 920, true, 1).step == 1);

    std::cout << "two-finger-focus tests passed\n";
}
