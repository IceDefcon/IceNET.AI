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

        cyusb_handle *m_usbHandle;
        struct libusb_config_descriptor *m_configDescriptor;
        struct libusb_device_descriptor m_deviceDescriptors;
        const struct libusb_endpoint_descriptor *m_endPointDescriptors;
        struct libusb_ss_endpoint_companion_descriptor *m_endPointCompanionDescriptors;
        const struct libusb_interface *m_usbInterface;
        const struct libusb_interface_descriptor *m_usbInterfaceDescriptors;

    public:
        device(std::shared_ptr<console> pConsole);
        ~device();

        void updateDevicelist();
        void getDeviceDetails();
        void getConfigDetails();

};
