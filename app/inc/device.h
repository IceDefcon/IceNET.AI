/* IceNET Robotics 2026 */

#pragma once

#include <iostream>

#include "cyusb.h" /* Cypress Library */
#include "console.h"
#include "deviceTypes.h"

class device
{
    private:

        std::shared_ptr<console> m_instanceConsole;

    public:
        device(std::shared_ptr<console> pConsole);
        ~device();

        void update_devlist();

};
