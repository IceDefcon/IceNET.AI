/* IceNET Robotics 2026 */

#include "device.h"

device::device(std::shared_ptr<console> pConsole) :
m_instanceConsole(pConsole)
{
    std::cout << "[INFO] [CONSTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;
}

device::~device()
{
    std::cout << "[INFO] [DESTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;
}

cyusb_handle  *usbHandle = NULL;
void device::update_devlist()
{
    int r;
    int index = 0;
    int num_interfaces;
    char tbuf[60];
    struct libusb_config_descriptor *configDescriptor = NULL;

    usbHandle = cyusb_gethandle(0);

    sprintf(tbuf,"VID=%04x, PID=%04x, BusNum=%02x, Addr=%d", cyusb_getvendor(usbHandle), cyusb_getproduct(usbHandle), cyusb_get_busnumber(usbHandle), cyusb_get_devaddr(usbHandle));
    m_instanceConsole->printConsole(INFO, tbuf);

    r = cyusb_get_active_config_descriptor (usbHandle, &configDescriptor);
    if(configDescriptor)
    {
        num_interfaces = configDescriptor->bNumInterfaces;
        m_instanceConsole->printConsole(INFO, "Number of interfaces: " + QString::number(num_interfaces));
    }
    else
    {
        m_instanceConsole->printConsole(ERNO, "Missing Destriptors");
    }

    while (num_interfaces)
    {
        if (cyusb_kernel_driver_active (usbHandle, index))
        {
            cyusb_detach_kernel_driver (usbHandle, index);
        }
        index++;
        num_interfaces--;
    }
    cyusb_free_config_descriptor (configDescriptor);
}
