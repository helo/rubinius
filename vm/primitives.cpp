#include "prelude.hpp"
#include "vm.hpp"
#include "primitives.hpp"
#include "event.hpp"
#include "gen/includes.hpp"

#include <iostream>

namespace rubinius {
  bool Primitives::unknown_primitive(STATE, Executable* exec, Task* task, Message& msg) {
    std::string message = std::string("Called unbound or invalid primitive from: ");
    message += msg.name->to_str(state)->c_str();

    Exception::assertion_error(state, message.c_str());

    return false;
  }

#include "gen/primitives_glue.gen.cpp"
}
