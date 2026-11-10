#pragma once

// Track a vertical finger-scroll sequence independently of the compositor API.
#include <algorithm>
#include <cmath>
#include <cstdint>

namespace TouchpadInertia {

class ScrollState {
  public:
    static constexpr double MinimumVelocity = 0.02; // Input units per millisecond.
    static constexpr double MaximumVelocity = 1.5;
    static constexpr uint64_t ReleaseWindowMs = 80;
    static constexpr uint64_t IdleResetMs = 150;
    static constexpr uint64_t MaximumDurationMs = 1500;

    void reset() { *this = ScrollState{}; }
    bool decaying() const { return momentum; }

    void horizontal(double delta, uint64_t now) {
        if (!std::isfinite(delta)) { reset(); return; }
        if (delta == 0) return;
        prepare(now);
        horizontalDistance += std::abs(delta);
        blocked = blocked || (horizontalDistance >= 18 && horizontalDistance > 1.5 * verticalDistance);
        lastEvent = now;
    }

    void vertical(double delta, uint64_t now) {
        if (!std::isfinite(delta) || delta == 0) {
            reset();
            return;
        }
        prepare(now);
        verticalDistance += std::abs(delta);
        if (tracking && now > lastMotion) {
            const auto elapsed = now - lastMotion;
            const double sample = std::clamp(delta / elapsed, -MaximumVelocity, MaximumVelocity);
            const double weight = 1 - std::exp(-static_cast<double>(elapsed) / 35);
            if (samples == 1 || std::signbit(sample) != std::signbit(velocity))
                velocity = sample;
            else
                velocity += weight * (sample - velocity);
        }
        tracking = true;
        ++samples;
        lastMotion = lastEvent = now;
    }

    bool release(uint64_t now) {
        momentum = tracking && !blocked && samples >= 2 && now >= lastMotion &&
            now - lastMotion <= ReleaseWindowMs && std::abs(velocity) >= MinimumVelocity;
        tracking = false;
        if (!momentum) {
            reset();
            return false;
        }
        started = lastTick = now;
        return true;
    }

    double advance(uint64_t now, double decayMs) {
        if (!momentum || now < lastTick || now - lastTick > IdleResetMs || now - started > MaximumDurationMs) {
            reset();
            return 0;
        }
        const double elapsed = now - lastTick;
        lastTick = now;
        velocity *= std::exp(-elapsed / std::clamp(decayMs, 40.0, 600.0));
        if (std::abs(velocity) < MinimumVelocity) {
            reset();
            return 0;
        }
        return velocity * elapsed;
    }

  private:
    void prepare(uint64_t now) {
        if (momentum || now < lastEvent || now - lastEvent > IdleResetMs)
            reset();
    }

    bool tracking = false, momentum = false, blocked = false;
    unsigned samples = 0;
    uint64_t lastMotion = 0, lastEvent = 0, lastTick = 0, started = 0;
    double velocity = 0, horizontalDistance = 0, verticalDistance = 0;
};

} // namespace TouchpadInertia
