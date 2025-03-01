#pragma once

#include <common/console.hpp>
#include <common/object.hpp>

#include <modules/sensor/sensor.hpp>

#include <utilities/sensor/accelerometer.hpp>
#include <utilities/sensor/gyroscope.hpp>

#include <utilities/bidirectionalmap/bidirectionalmap.hpp>
#include <utilities/guid.hpp>

#include <memory>
#include <vector>

namespace love
{
    template<Console::Platform T = Console::ALL>
    class Joystick : public Object
    {
      public:
        static inline Type type = Type("Joystick", &Object::type);

        enum GamepadAxis
        {
            GAMEPAD_AXIS_LEFTY,
            GAMEPAD_AXIS_LEFTX,
            GAMEPAD_AXIS_RIGHTY,
            GAMEPAD_AXIS_RIGHTX,
            GAMEPAD_AXIS_TRIGGERLEFT,
            GAMEPAD_AXIS_TRIGGERRIGHT,
            GAMEPAD_AXIS_MAX_ENUM
        };

        enum GamepadButton
        {
            GAMEPAD_BUTTON_INVALID,
            GAMEPAD_BUTTON_A,
            GAMEPAD_BUTTON_B,
            GAMEPAD_BUTTON_X,
            GAMEPAD_BUTTON_Y,
            GAMEPAD_BUTTON_BACK,
            GAMEPAD_BUTTON_GUIDE,
            GAMEPAD_BUTTON_START,
            GAMEPAD_BUTTON_LEFTSTICK,
            GAMEPAD_BUTTON_RIGHTSTICK,
            GAMEPAD_BUTTON_LEFTSHOULDER,
            GAMEPAD_BUTTON_RIGHTSHOULDER,
            GAMEPAD_BUTTON_DPAD_UP,
            GAMEPAD_BUTTON_DPAD_DOWN,
            GAMEPAD_BUTTON_DPAD_LEFT,
            GAMEPAD_BUTTON_DPAD_RIGHT,
        };

        enum InputType
        {
            INPUT_TYPE_AXIS,
            INPUT_TYPE_BUTTON,
            INPUT_TYPE_MAX_ENUM
        };

        struct JoystickInput
        {
            InputType type;

            GamepadAxis axis;
            int axisNumber;

            GamepadButton button;
            int buttonNumber;
        };

        Joystick() : sensors()
        {}

        virtual ~Joystick()
        {}

        std::string GetName() const
        {
            return this->name;
        }

        int GetInstanceID()
        {
            return this->instanceId;
        }

        int GetID() const
        {
            return this->id;
        }

        std::string GetGUID() const
        {
            return this->guid;
        }

        std::unique_ptr<uint8_t>::pointer GetHandle() const
        {
            return this->handle.get();
        }

        // clang-format off
        static constexpr BidirectionalMap inputTypes = {
            "axis",   INPUT_TYPE_AXIS,
            "button", INPUT_TYPE_BUTTON
        };

        static constexpr BidirectionalMap buttonTypes = {
            "a",             GAMEPAD_BUTTON_A,
            "b",             GAMEPAD_BUTTON_B,
            "x",             GAMEPAD_BUTTON_X,
            "y",             GAMEPAD_BUTTON_Y,
            "back",          GAMEPAD_BUTTON_BACK,
            "guide",         GAMEPAD_BUTTON_GUIDE,
            "start",         GAMEPAD_BUTTON_START,
            "leftstick",     GAMEPAD_BUTTON_LEFTSTICK,
            "rightstick",    GAMEPAD_BUTTON_RIGHTSTICK,
            "leftshoulder",  GAMEPAD_BUTTON_LEFTSHOULDER,
            "rightshoulder", GAMEPAD_BUTTON_RIGHTSHOULDER,
            "dpup",          GAMEPAD_BUTTON_DPAD_UP,
            "dpdown",        GAMEPAD_BUTTON_DPAD_DOWN,
            "dpleft",        GAMEPAD_BUTTON_DPAD_LEFT,
            "dpright",       GAMEPAD_BUTTON_DPAD_RIGHT
        };

        static constexpr BidirectionalMap axisTypes = {
            "leftx",        GAMEPAD_AXIS_LEFTX,
            "lefty",        GAMEPAD_AXIS_LEFTY,
            "rightx",       GAMEPAD_AXIS_RIGHTX,
            "righty",       GAMEPAD_AXIS_RIGHTY,
            "triggerleft",  GAMEPAD_AXIS_TRIGGERLEFT,
            "triggerright", GAMEPAD_AXIS_TRIGGERRIGHT
        };

        static constexpr float JoystickMax = 150.0f;

      protected:
        std::string name;

        int instanceId;
        int id;

        std::string guid;
        std::unique_ptr<uint8_t> handle;

        std::map<Sensor::SensorType, SensorBase*> sensors;
    };
} // namespace love
