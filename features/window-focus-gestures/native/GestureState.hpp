#pragma once

// A touchpad scroll sequence can select one window after a horizontal threshold.
// Context is fixed at sequence start. Single-window and vertical sequences pass through.
#include <cmath>
#include <cstdint>

namespace TwoFingerFocus {

enum class Axis { Horizontal, Vertical };

struct Result {
    bool consume = false;
    int step = 0;
};

class GestureState {
  public:
    static constexpr double Threshold = 18.0;
    static constexpr double HorizontalRatio = 1.5;
    // Recover when a device or interrupted input sequence omits its axis-stop event.
    static constexpr uint64_t IdleResetMs = 400;

    void reset() { *this = GestureState{}; }

    Result update(Axis axis, double delta, uint64_t now, bool enabled, int64_t workspace) {
        if (!std::isfinite(delta)) {
            reset();
            return {};
        }
        if (active && now - lastEvent > IdleResetMs)
            reset();

        if (delta == 0) {
            const bool consumed = active && eligible && enabled && workspace == ownerWorkspace && axis == Axis::Horizontal;
            if (axis == Axis::Horizontal || horizontal == 0)
                reset();
            return {consumed, 0};
        }

        if (!active) {
            active = true;
            eligible = enabled;
            ownerWorkspace = workspace;
        }
        lastEvent = now;
        if (!enabled || workspace != ownerWorkspace)
            eligible = false;
        if (!eligible)
            return {};

        if (axis == Axis::Vertical) {
            vertical += std::abs(delta);
            if (!fired && vertical >= Threshold && vertical > std::abs(horizontal))
                eligible = false;
            return {};
        }

        horizontal += delta;
        if (!fired && std::abs(horizontal) >= Threshold && std::abs(horizontal) >= HorizontalRatio * vertical) {
            fired = true;
            return {true, horizontal > 0 ? 1 : -1};
        }
        return {true, 0};
    }

  private:
    bool active = false;
    bool eligible = false;
    bool fired = false;
    int64_t ownerWorkspace = 0;
    uint64_t lastEvent = 0;
    double horizontal = 0;
    double vertical = 0;
};

} // namespace TwoFingerFocus
